import Foundation
import BackgroundTasks
import SwiftSyft
import Alamofire

public class Artificien {
    
    let masterNode = "http://orche-PyGri-5APKUWIHYWZ2-fabeedcb5955fdaf.elb.us-east-1.amazonaws.com:5001"
    var chargeDetection: Bool
    var wifiDetection: Bool
    var client: SyftClient?
    
    public init(chargeDetection: Bool = true, wifiDetection: Bool = true) {
        self.chargeDetection = chargeDetection
        self.wifiDetection = wifiDetection
    }
    
    // TODO: Show them in the web portal how they need to structure their data
    public func train(trainingData: [String: Float], validationData: [String: Float], backgroundTask: BGTask? = nil) {
                
        // TODO: pull this from a plist
        let parameters: [String: Any] = ["dataset_id": "dataSetFive"]

        Alamofire.request(masterNode + "/info", method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON() { response in
            
            switch response.result {
            
            case .success(let json):
                let responseDict = json as! [String : Any]
                let models = responseDict["models"] as! [[String]]
                let nodeURL = responseDict["nodeURL"] as! String
                
                // Create a client with a PyGrid server URL
                guard let syftClient = SyftClient(url: URL(string: "http://" + nodeURL + ":5000/")!) else {
                    // TODO: Set up some way to alert us that this doesn't work
                    
                    // Set background task failed if creating a client fails
                    backgroundTask?.setTaskCompleted(success: false)
                    return
                }
                
                // Store the client as a property so it doesn't get deallocated during training.
                self.client = syftClient
                                
                // Loop through models and train them
                let group = DispatchGroup()
                for model in models {
                    
                    let modelName = model[0]
                    let modelVersion = model[1]
                    
                    var backgroundTaskCancelled = false
                    
                    group.enter()
                    
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
                        
                        // Prepare data arrays (sort by key alphabetically and select value)
                        // TODO: check that key names are what they should be
                        let trainingArray = trainingData.sorted{ $0.key < $1.key }.map({ $0.1 })
                        let validationArray = validationData.sorted{ $0.key < $1.key }.map({ $0.1 })
                        
                        do {
                            
                            // Since we don't have native tensor wrappers in Swift yet, we use `TrainingData` and `ValidationData` classes to store the data and shape.
                            let trainingTensor = try TrainingData(data: trainingArray, shape: [clientConfig.batchSize, trainingArray.count / clientConfig.batchSize])
                            let validationTensor = try ValidationData(data: validationArray, shape: [clientConfig.batchSize, validationArray.count / clientConfig.batchSize])
                            
                            // Execute the plan with the training data and validation data.
                            // TODO: return the loss somewhere
                            let loss = plan.execute(trainingData: trainingTensor, validationData: validationTensor, clientConfig: clientConfig)
                            
                            // Generate diff data and report the final diffs as
                            let diffStateData = try plan.generateDiffData()
                            modelReport(diffStateData)
                            
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
                    })
                    
                    // This is the error handler for being rejected in a cycle. You can retry again
                    // after the suggested timeout.
                    syftJob.onRejected(execute: { timeout in
                        
                        if let timeout = timeout {
                            // Retry again after timeout
                            print(timeout)
                        }
                        group.leave()
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
