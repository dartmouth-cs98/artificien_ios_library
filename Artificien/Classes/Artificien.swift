//
//  Artificien.swift
//  Artificien
//
//  Created by Shreyas Agnihotri on 01/18/2021.
//  Copyright (c) 2021 Shreyas Agnihotri. All rights reserved.
//

import Foundation
import BackgroundTasks
import SwiftSyft
import Alamofire

public class Artificien {
    
    let masterNode = "http://orche-pygri-1otammo0acarg-74b44bcdcc5f77f0.elb.us-east-1.amazonaws.com:5001"
    var chargeDetection: Bool
    var wifiDetection: Bool
    var client: SyftClient?
    
    // Create class and set global configuration for charging and wifi
    public init(chargeDetection: Bool = true, wifiDetection: Bool = true) {
        self.chargeDetection = chargeDetection
        self.wifiDetection = wifiDetection
    }
    
    public func reportLoss(loss: Float, modelName: String) {
        
        // Report model loss to master node (accuracy currently not recorded)
        let lossResponse = AF.request(self.masterNode + "/model_loss", method: .post, parameters: ["acc": -1, "loss": loss, "model_id": modelName], encoding: JSONEncoding.default).validate().responseJSON
        print(lossResponse)
    }

    // Pull and train all necessary models given application data
    public func train(data: [String: Float], backgroundTask: BGTask? = nil) {
        
        // Set background task failed if plist not found
        guard let plistPath = Bundle.main.path(forResource: "Artificien", ofType: "plist") else {
            backgroundTask?.setTaskCompleted(success: false)
            return
        }
        
        // Set background task failed if plist not in dictionary format
        guard let plistDict = NSDictionary(contentsOfFile: plistPath) as? [String: String] else {
            backgroundTask?.setTaskCompleted(success: false)
            return
        }
        
        // Set background task failed if keys not found
        guard let datasetID: String = plistDict["dataset_id"], let apiKey: String = plistDict["api_key"] else {
            backgroundTask?.setTaskCompleted(success: false)
            return
        }

        // Pull all active models for this app from master node using Plist dataset_id and api_key
        AF.request(masterNode + "/info", method: .post, parameters: ["dataset_id": datasetID], encoding: JSONEncoding.default, headers: ["api_key": apiKey]).validate().responseJSON() { response in

            switch response.result {

            case .success(let json):
                let responseDict = json as! [String : Any]
                guard responseDict.count != 1 else {
                    // Terminate early if response from server is merely confirming connection (on first setup call)
                    // or is no node is available
                    backgroundTask?.setTaskCompleted(success: false)
                    return
                }
                let models = responseDict["models"] as! [[Any]]
                let nodeURL = responseDict["nodeURL"] as! String
                        
                // Create a client with a PyGrid server URL
                guard let syftClient = SyftClient(url: URL(string: "http://" + nodeURL + ":5000/")!) else {
                    
                    // Set background task failed if creating a client fails
                    backgroundTask?.setTaskCompleted(success: false)
                    return
                }
                
                // Store the client as a property so it doesn't get deallocated during training.
                self.client = syftClient
                                
                // Loop through models and train them in parallel
                let group = DispatchGroup()
                for model in models {

                    let modelName = model[0] as! String
                    let modelVersion = model[1] as! String
                    let trainingVariables = model[2] as! [String]
                    let validationVariables = model[3] as! [String]
                    
                    var backgroundTaskCancelled = false // Track whether to short-circuit background task
                    group.enter() // Enter parallel batch
                    
                    // Create SwiftSyft worker job for current model
                    guard let syftJob: SyftJob = self.client?.newJob(modelName: modelName, version: modelVersion) else {
                        
                        // Jump to next model if creating a job fails
                        group.leave()
                        continue
                    }
                    
                    // This function is called when SwiftSyft has downloaded the plans and model parameters from PyGrid
                    // You are ready to train your model on your data
                    // plan - Use this to generate diffs using our training data
                    // clientConfig - contains the configuration for the training cycle (batchSize, learning rate) and metadata for the model (name, version)
                    // modelReport - Used as a completion block and reports the diffs to PyGrid.
                    syftJob.onReady(execute: { plan, clientConfig, modelReport in
                        
                        // This checks if the background task has been cancelled. If it is, go to the next the training cycle
                        guard !backgroundTaskCancelled else {
                            group.leave()
                            return
                        }
                        
                        // Prepare training data as tensor as requested by data analyst
                        var trainingArray: [Float] = []
                        for variable in trainingVariables {
                            if let providedVariable = data[variable] {
                                trainingArray.append(providedVariable)
                            } else {
                                // App developer did not provide requested variable; terminate training
                                group.leave()
                                return
                            }
                        }

                        // Prepare validation data as tensor as requested by data analyst
                        var validationArray: [Float] = []
                        for variable in validationVariables {
                            if let providedVariable = data[variable] {
                                validationArray.append(providedVariable)
                            } else {
                                // App developer did not provide requested variable; terminate training
                                group.leave()
                                return
                            }
                        }
                        
                        do {
                            
                            // Create tensors for trainina and validation data
                            // Since we don't have native tensor wrappers in Swift yet, we use `TrainingData` and `ValidationData` classes to store the data and shape.
                            let trainingTensor = try TrainingData(data: trainingArray, shape: [clientConfig.batchSize, trainingArray.count / clientConfig.batchSize])
                            let validationTensor = try ValidationData(data: validationArray, shape: [clientConfig.batchSize, validationArray.count / clientConfig.batchSize])
                            
                            // Execute the plan with the training data and validation data.
                            let loss = plan.execute(trainingData: trainingTensor, validationData: validationTensor, clientConfig: clientConfig)
                            let absoluteLoss = abs(loss)

                            // Report model loss to master node (accuracy currently not recorded)
                            AF.request(self.masterNode + "/model_loss", method: .post, parameters: ["acc": -1, "loss": absoluteLoss, "model_id": modelName], encoding: JSONEncoding.default).responseString { response in
                                if let statusCode = response.response?.statusCode {
                                    print("\(statusCode)")
                                }
                            }
                            
                            // Store training result in UserDefaults in case app wishes to use it
                            UserDefaults.standard.set("\(absoluteLoss)", forKey: "trainingResult")
                            
                            // Generate diff data and report the final diffs
                            let diffStateData = try plan.generateDiffData()
                            modelReport(diffStateData)
                            
                            group.leave()
                            return
                            
                        } catch let error {
                            
                            // Handle any error from the training cycle
                            debugPrint(error.localizedDescription)
                            group.leave()
                            return
                        }
                        
                    })
                    
                    // This is the error handler for any job execution errors like connecting to PyGrid
                    syftJob.onError(execute: { error in
                        
                        print(error.localizedDescription)
                        group.leave()
                        return
                    })
                    
                    // This is the error handler for being rejected in a cycle. You can retry again
                    // after the suggested timeout.
                    syftJob.onRejected(execute: { timeout in
                        
                        if let timeout = timeout {
                            // Retry again after timeout
                            print(timeout)
                        }
                        group.leave()
                        return
                    })
                    
                    // Start the job. You can set that the job should only execute if the device is being charge and there is a WiFi connection.
                    // These options are true by default if you don't specify them.
                    syftJob.start(chargeDetection: self.chargeDetection, wifiDetection: self.wifiDetection)
                    
                    // If the background task has expired,
                    // we set this flag as true so that the training cycle
                    // can be informed and cancel any following cycles
                    backgroundTask?.expirationHandler = {
                        backgroundTaskCancelled = true
                    }
                    
                }

                group.notify(queue: .main) {
                    print("Artificien model tasks complete")
                    // Finish the background task
                    backgroundTask?.setTaskCompleted(success: true)
                }
                
            case .failure(let error):

                // Set background task failed if fetching models fails
                print(error)
                backgroundTask?.setTaskCompleted(success: false)
                return
            }
        }
    }
}
