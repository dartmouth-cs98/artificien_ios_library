import Foundation
import BackgroundTasks
import SwiftSyft

//enum ArtificienError: Error {
//    case invalidNodeURL
//}

struct Job {
    var name: String
    var version: String
    
    init(jobName: String, jobVersion: String) {
        name = jobName
        version = jobVersion
    }
}

public class Artificien {
    var nodeAddress: String
    var client: SyftClient?
    
    public init(nodeAddress: String) {
        self.nodeAddress = nodeAddress
    }
    
    public func temp() {
        print("this prints to the console so we can see if this is working!")
    }
    
    public func train(trainingData: [String: Float], validationData: [String: Float], backgroundTask: BGTask? = nil) {
        
        print("Hello world")
        
        // Create a client with a PyGrid server URL
        guard let syftClient = SyftClient(url: URL(string: nodeAddress)!) else {
            
            // TODO: Set up some way to alert us that this doesn't work
            
            // Set background task failed if creating a client fails
            backgroundTask?.setTaskCompleted(success: false)
            return
        }
        
        // Store the client as a property so it doesn't get deallocated during training.
        self.client = syftClient
        
        // TODO: Fetch Models to Train
        let jobs = [Job(jobName: "perceptron", jobVersion: "0.3.0")]
        
        // Loop through models and train them
        let group = DispatchGroup()
        for job in jobs {
            
            var backgroundTaskCancelled = false
            
            group.enter()
            
            var syftJob: SyftJob
            syftJob = syftClient.newJob(modelName: job.name, version: job.version)
            
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
            
            // This is the error handler for any job exeuction errors like connecting to PyGrid
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
            })
            
            // Start the job. You can set that the job should only execute if the device is being charge and there is a WiFi connection.
            // These options are true by default if you don't specify them.
            syftJob.start(chargeDetection: true, wifiDetection: true)
            
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
        
    }
}
