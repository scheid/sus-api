import Vapor

/// Register your application's routes here.
public func routes(_ app: Application) throws {


    let susController = SusController()
    

    app.get("sus-api", use: susController.getProjectListExtended)
    app.get("sus-api", "susscores", use: susController.index)
    app.get("sus-api", "susscores", ":projectId", use: susController.getProjectData)
    app.get("sus-api", "susscores", "download", ":projectId", use: susController.getProjectDataCsv)
    
    app.get("sus-api", "util", "get-new-auth-key", use: susController.getNewKey)
    
    app.post("sus-api", "susscore", use: susController.create)
    app.delete("sus-api", "susscore", ":susScore", use: susController.delete)
    
    app.get("sus-api", "susscores", "summary", ":projectId", use: susController.getProjectSumary)
    
}
