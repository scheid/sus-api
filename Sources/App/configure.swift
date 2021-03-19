import Fluent
import FluentSQLiteDriver

import Vapor
import Leaf
import Foundation

// configures your application
public func configure(_ app: Application) throws {
    

    
    //let dbPath = DirectoryConfig.detect().workDir + "sus-scores.sqlite"
  //  let dbPath = "\(FileManager.default.currentDirectoryPath)/sus-scores.sqlite"
    
  //  let dbPath = "/Users/teischeid/swift-projects/sus/sus-scores.sqlite"
    
    let dbPath = "/home/srvadmin/swiftapps/sus-api/sus-scores.sqlite"
    
  //  print("dbpath = \(dbPath)")
    
    app.databases.use(.sqlite(.file(dbPath)), as: .sqlite)
    
 
   // app.migrations.add(CreateTable())
 
    
  //  app.http.server.configuration.port = 9292
  //  app.http.server.configuration.hostname = "0.0.0.0"

    
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

 //   let leafTmp = "/Users/teischeid/swift-projects/sus/Resources/Views"
    

   // LeafEngine.rootDirectory = leafTmp
    
    // TME: added for leaf templating
    app.views.use(.leaf)
    
    
    // register routes
    try routes(app)
}
