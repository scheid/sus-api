import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {

    // Basic "It works" example
   // router.get("sus-api") { req in
   //     return "SUS API works!"
  //  }

    let susController = SusController()
    

    router.get("sus-api", use: susController.getProjectListExtended)
    router.get("sus-api/susscores", use: susController.index)
    router.get("sus-api/susscores/", String.parameter, use: susController.getProjectData)
    router.get("sus-api/susscores/download", String.parameter, use: susController.getProjectDataCsv)
    
    router.get("sus-api/util/get-new-auth-key", use: susController.getNewKey)
    
    router.post("sus-api/susscore", use: susController.create)
    router.delete("sus-api/susscore", SusScore.parameter, use: susController.delete)
    
    router.get("sus-api/susscores/summary", String.parameter, use: susController.getProjectSumary)
    
}
