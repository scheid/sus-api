import Fluent
import FluentSQLiteDriver
import Vapor
import Foundation


struct SusScoreError: Error {
    
    var message: String
}


/// Controls basic CRUD operations on `SUSScore`s.
final class SusController {
    
    /// Returns a list of all
    func index(_ request: Request) throws -> EventLoopFuture<[SusScore]> {
        return SusScore.query(on: request.db).all()
    }
    
    
    //get a new auth key, just as a plain string; this is intended just as a utility route, when a new key is needed.
    func getNewKey(_ request: Request) throws -> EventLoopFuture<String> {
        let promise = request.eventLoop.makePromise(of: String.self)
        
        let prng = Prng(seed: nil)
        
        let newKey = prng.getHexString(length: 16)
        
        promise.succeed(newKey)
        
        return promise.futureResult
        
    }
    
    func getProjectList(_ request: Request) throws -> EventLoopFuture<Response> {
        
        
        if let sqlDb = request.db as? SQLDatabase {
            
            //running the raw sql  will return an array of a dictionary of SQLiteColumn as the key and SQLiteData as the value
            //  get the column name by using the .name property.  the value is just directly obtained from the SQLiteData object.
            
            
            let items = sqlDb.raw("""
               
            SELECT DISTINCT projectId FROM `SusScore`;
               
            """).all()
            
           
            return items.flatMap { (projItems: [SQLRow]) -> EventLoopFuture<Response> in
                
                let projPromise = request.eventLoop.makePromise(of: Response.self)
                var projectNames = [String]()
                
                
                do {
                    
                    
                    try projItems.forEach { projectItem in
                        
                        let _val: String = try projectItem.decode(column: "projectId", as: String.self)
                        
                        projectNames.append(  _val.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) )
                        
                    }
                                
                        
                    let projData = try JSONEncoder().encode(projectNames)
                    
                    // create http response object; set body value
                    let response = Response(status: .ok, body: Response.Body( string: String(data: projData, encoding: .utf8) ?? "{\"error\": true}") )
                    response.headers.add(name: .contentType, value: "application/json")
                 
                    projPromise.succeed(response)

                } catch {  // NOTE: when you don't include a param on the 'catch' (e.g., catch let err as Error), then it will be a catch ALL.
                           // when you put a param on the catch, it tells the compiler that it won't catch every error, just the ones you have cast for that catch block.
                    projPromise.fail(SusScoreError(message: "could not create project list from database data"))
                }
                    
                return projPromise.futureResult
        
            }
            
            
        } else {
            throw SusScoreError(message: "database error. database may not be an sql database.")
        }
        
      
        

        
        
        
    }
    
    
    
    func getProjectListFormatted(_ request: Request) throws -> EventLoopFuture<View> {
        
        struct ProjectListData: Encodable {
            var projectList: [String]
            var projectCount: Int
        }
        
        
        if let sqlDb = request.db as? SQLDatabase {
            
            
            //running the raw sql  will return an array of a dictionary of SQLiteColumn as the key and SQLiteData as the value
            //  get the column name by using the .name property.  the value is just directly obtained from the SQLiteData object.
            
            
            let items = sqlDb.raw("""
               
            SELECT DISTINCT project_id FROM `SusScore`;
               
            """).all()
        
            
            return items.flatMap { (projItems: [SQLRow]) -> EventLoopFuture<View> in
                         
                var projectNames = [String]()
                
                do {
                    
                    try projItems.forEach { projectItem in
                        
                        let _val: String = try projectItem.decode(column: "projectId", as: String.self)
                        /// .replace (/(^")|("$)/g, "")  // this regex trims beginngin and ending quotes too.
                            
                        // FIXME: returns a description of the value rather than the value as a string
                        projectNames.append( _val.trimmingCharacters(in: CharacterSet(charactersIn: "\""))  )
                        
                    }
                            
                    
                    return request.view.render("project-list.html.leaf", ProjectListData(projectList: projectNames, projectCount: projectNames.count))

                } catch {  // NOTE: when you don't include a param on the 'catch' (e.g., catch let err as Error), then it will be a catch ALL.
                           // when you put a param on the catch, it tells the compiler that it won't catch every error, just the ones you have cast for that catch block.
                    
                    // TODO: this is really a failure condition but the teamplate wouldn't reflect that fact
                    return request.view.render("project-list.html.leaf", ProjectListData(projectList: [String](), projectCount: 0))
                }
                    
                
                
        
            }
            
        } else {
            throw SusScoreError(message: "database error. database may not be an sql database.")
        }
        
        
        

        
        
        
    }
    
    
    
    
    func getProjectDataCsv(_ request: Request) throws -> EventLoopFuture<Response> {
    
      //  let projectId = try request.parameters.next(String.self)
    
        guard let projectId = request.parameters.get("projectId") else {
          throw SusScoreError(message: "cannot determine projectId")
        }
        
        if let sqlDb = request.db as? SQLDatabase {
            
            let items = sqlDb.raw("""
               
            SELECT * FROM `SusScore` WHERE project_id=="\(projectId)";
               
            """).all(decoding: SusScore.self)
            
            
            return items.flatMap { (scoreItems: [SusScore]) -> EventLoopFuture<Response> in
                let csvPromise = request.eventLoop.makePromise(of: Response.self)
                
                // TODO: how do I put this in an async function instead of inline ?
                // this defeats the purpose of promises, but not sure how to solve it.
                var scoreItems2 = [String]()
                
                if scoreItems.count > 0 {
                    scoreItems2.append(scoreItems[0].csvHeader())
                }
                
                
            
                scoreItems.forEach { scoreItem in
                    scoreItems2.append(scoreItem.asCsvString())
                }
                
                // create http response object; set body value to the csv string, and set the header so the browser will download as file.
                var response = Response(status: .ok, body: Response.Body(string: scoreItems2.joined(separator: "\n")))
                response.headers.add(name: .contentDisposition, value: "attachment; filename=\"sus-scores-\(projectId).csv\"")
                
                csvPromise.succeed(response)

                return csvPromise.futureResult
        
            }
            
        } else {
            throw SusScoreError(message: "database error; database may not be a SQL database.")
        }
        
        

        
        
    
    
    }
    
    
    // returns a rendered html view of the project summary.
    func getProjectSumary(_ request: Request) throws -> EventLoopFuture<View> {
        
        struct SusProjectSummary: Codable {
            var projectId: String
            var susScoreMean: Double
            var susScoreMeanFormatted: String
            var observationsCount: Int
            
        }
        
        
      
        guard let projectId = request.parameters.get("projectId") else {
          throw SusScoreError(message: "cannot determine projectId")
        }
        
        // we will round the calculated score so it is only 1 decimal place.
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.roundingMode = NumberFormatter.RoundingMode.halfUp
        formatter.maximumFractionDigits = 1
        
        
        if let sqlDb = request.db as? SQLDatabase {
            let items = sqlDb.raw("""
               
            SELECT * FROM `SusScore` WHERE project_id=="\(projectId)";
               
            """).all(decoding: SusScore.self)
            
            
            return items.flatMap { (scoreItems: [SusScore]) -> EventLoopFuture<View> in
                
                var tmpSum = [Double]()
                
                scoreItems.forEach { (scoreObj: SusScore) in
                    tmpSum.append( scoreObj.calcScore() )
                }
                
                let scoresSum = tmpSum.reduce(0, { val1, val2 in
                    val1 + val2
                })
                
                return request.view.render("project-summary.html.leaf", SusProjectSummary(projectId: projectId, susScoreMean: scoresSum / Double(scoreItems.count), susScoreMeanFormatted: formatter.string(from: NSNumber(value: scoresSum / Double(scoreItems.count))) ?? ""  ,  observationsCount: scoreItems.count))
                
            }
            
            
        } else {
            throw SusScoreError(message: "database error; database may not be a SQL database.")
        }
        
        
        
        
        
        
    }
    
    
    
    
    // returns a rendered html view of the project summary; with additional information.
    func getProjectListExtended(_ request: Request) throws -> EventLoopFuture<View> {
        
        struct SusProjectSummary: Codable {
            var projectId: String
            var susScoreMean: Double
            var susScoreMeanFormatted: String
            var observationsCount: Int
            var minDate: Date?
            var maxDate: Date?
            var minDateFormatted: String?
            var maxDateFormatted: String?
            
        }
        
        struct AllProjectsViewData: Codable {
            var projectSummaries: [SusProjectSummary]
            var projectCount: Int
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT-4:00") //Current time zone
        
        
        // typealias SusTasksScores = [SusTaskSummary]
        var projectSummaries = [SusProjectSummary]()
        
        
        // we will round the calculated score so it is only 1 decimal place.
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.roundingMode = NumberFormatter.RoundingMode.halfUp
        formatter.maximumFractionDigits = 1
        
        
        let items = SusScore.query(on: request.db).all()
        

        return items.flatMap { (scoreItems: [SusScore]) -> EventLoopFuture<View> in
            
        //    var tmpSum = [Double]()
            var uniqueProjects = [String:[Double]]()
            var uniqueProjectsMinDate = [String: Date]()
            var uniqueProjectsMaxDate = [String: Date]()
            
            // create a double array for each task id
            scoreItems.forEach { (scoreObj: SusScore) in
                if uniqueProjects[scoreObj.projectId] == nil {
                    
                    uniqueProjects[scoreObj.projectId] = [Double]()
                }
            }
            
            // calculate the SUS scores for each response and determine the min and max dates for each project
            scoreItems.forEach { (scoreObj: SusScore) in
                uniqueProjects[scoreObj.projectId]!.append(scoreObj.calcScore())
                
                if let d = uniqueProjectsMinDate[scoreObj.projectId] {
                    uniqueProjectsMinDate[scoreObj.projectId] = min(d, scoreObj.dateStamp)
                } else {
                    uniqueProjectsMinDate[scoreObj.projectId] = scoreObj.dateStamp
                }
                
                
                if let d = uniqueProjectsMaxDate[scoreObj.projectId] {
                    uniqueProjectsMaxDate[scoreObj.projectId] = max(d, scoreObj.dateStamp)
                } else {
                    uniqueProjectsMaxDate[scoreObj.projectId] = scoreObj.dateStamp
                }
                
                
            }
            
            var tmpMax: String?
            var tmpMin: String?
            
            for (project, scores) in uniqueProjects {
                
                let scoresSum = scores.reduce(0, { val1, val2 in
                    val1 + val2
                })
                
                if let x = uniqueProjectsMinDate[project] {
                    tmpMin = dateFormatter.string(from: x)
                } else {
                    tmpMin = nil
                }
                
                if let x = uniqueProjectsMaxDate[project] {
                    tmpMax = dateFormatter.string(from: x)
                } else {
                    tmpMax = nil
                }
                
                
                projectSummaries.append(
                   SusProjectSummary(projectId: project,
                                   susScoreMean: scoresSum / Double(scores.count),
                                   susScoreMeanFormatted: formatter.string(from: NSNumber(value: scoresSum / Double(scores.count))) ?? "",
                                   observationsCount: scores.count,
                                   minDate: uniqueProjectsMinDate[project],
                                   maxDate: uniqueProjectsMaxDate[project],
                                   minDateFormatted: tmpMin,
                                   maxDateFormatted: tmpMax
                    )
                   
                  )
                
            }
            
            return request.view.render("project-list.html.leaf", AllProjectsViewData(projectSummaries: projectSummaries, projectCount: projectSummaries.count) )

        }
        
        
    }


    
    
    
   
    
    func getProjectData(_ request: Request) throws -> EventLoopFuture<[SusScore]> {
        
        
        guard let projectId = request.parameters.get("projectId") else {
          throw SusScoreError(message: "cannot determine projectId")
        }
        
    
        
        if let sqlDb = request.db as? SQLDatabase {
            return sqlDb.raw("""
                
             SELECT * FROM `SusScore` WHERE project_id=="\(projectId)";
                
             """).all(decoding: SusScore.self)
            
        
        } else {
            throw SusScoreError(message: "database error; database may not be a SQL database.")
        }
        
 
         
        //return TLXScore.query(on: request).filter(\TLXScore.projectId == projectId).all()
      
        /*
        // filter for both parent product and product
        return TLXScore.query(on: request).group(.and) { andGroup in
         //   andGroup.filter(\.projectId == projectId).filter(\.participantId == participantId)
            andGroup.filter(\.projectId == projectId)
        }.all() //.sort(\TLXScore.dateStamp, .ascending).all()
        */
        
    }
    
    
    
    
    func deleteProject(_ request: Request) throws -> EventLoopFuture<[SusScore]> {
        
        
        guard let projectId = request.parameters.get("projectId") else {
          throw SusScoreError(message: "cannot determine projectId")
        }

         
        if let sqlDb = request.db as? SQLDatabase {
            
            return sqlDb.raw("""
               
               DELETE FROM `SusScore` WHERE project_id=="\(projectId)";
                
               """).all(decoding: SusScore.self)
            
        } else {
            throw SusScoreError(message: "database error; database may not be a SQL database.")
        }
        
        

    }
    
    
    

    /// Saves a decoded `Sus` to the database.
    func create(_ req: Request) throws -> EventLoopFuture<SusScore> {
        
        
        let sus = try req.content.decode(SusScore.self)
        return sus.save(on: req.db).map { sus }
        
    }

    /// Deletes a parameterized `Sus`.
    // pass in the id of item to delete with name `susScoreId`
    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        
        guard let susScoreId = req.parameters.get("susScoreId") else {
          throw SusScoreError(message: "cannot determine projectId")
        }
        
       // let susScoreIdInt = Int(susScoreId)
        let susScoreIduid = UUID(susScoreId)
        
        return SusScore.find(susScoreIduid, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
        

    }
}

