import Vapor
import Foundation
import FluentSQLite

/// Controls basic CRUD operations on `SUSScore`s.
final class SusController {
    
    /// Returns a list of all
    func index(_ request: Request) throws -> Future<[SusScore]> {
        return SusScore.query(on: request).all()
    }
    
    
    //get a new auth key, just as a plain string; this is intended just as a utility route, when a new key is needed.
    func getNewKey(_ request: Request) throws -> Future<String> {
        let promise = request.eventLoop.newPromise(of: String.self)
        
        let prng = Prng(seed: nil)
        
        let newKey = prng.getHexString(length: 16)
        
        promise.succeed(result: newKey)
        
        return promise.futureResult
        
    }
    
    func getProjectList(_ request: Request) throws -> Future<HTTPResponse> {
        
        
        let items = request.withPooledConnection(to: .sqlite) { connection -> Future<[[SQLiteColumn:SQLiteData]]> in
            
            return connection.raw("""
               
            SELECT DISTINCT projectId FROM `SusScore`;
               
            """).all()

        }
        
        //running the raw sql above will return an array of a dictionary of SQLiteColumn as the key and SQLiteData as the value
        //  get the column name by using the .name property.  the value is just directly obtained from the SQLiteData object.
        
        
        return items.flatMap { (projItems: [[SQLiteColumn:SQLiteData]]) -> Future<HTTPResponse> in
            let projPromise = request.eventLoop.newPromise(of: HTTPResponse.self)
                     
            var projectNames = [String]()
            
            projItems.forEach { projectItem in
                
                for (key, val) in projectItem {
                    print("key: \(key.name). value: \(val)")
                    
                    projectNames.append(  _val.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) )
                    
                }
            }
                        
                
            let projData = try JSONEncoder().encode(projectNames)
            
            // create http response object; set body value
            var response = HTTPResponse(status: .ok, body: String(data: projData, encoding: .utf8) ?? "{\"error\": true}" )
            response.headers.add(name: .contentType, value: "application/json")
         
            projPromise.succeed(result: response)

            return projPromise.futureResult
    
        }
        
        
    }
    
    
    
    func getProjectListFormatted(_ request: Request) throws -> Future<View> {
        
        struct ProjectListData: Encodable {
            var projectList: [String]
            var projectCount: Int
        }
        
        let items = request.withPooledConnection(to: .sqlite) { connection -> Future<[[SQLiteColumn:SQLiteData]]> in
            
            return connection.raw("""
               
            SELECT DISTINCT projectId FROM `SusScore`;
               
            """).all()

        }
        
        //running the raw sql above will return an array of a dictionary of SQLiteColumn as the key and SQLiteData as the value
        //  get the column name by using the .name property.  the value is just directly obtained from the SQLiteData object.
        
        
        return items.flatMap { (projItems: [[SQLiteColumn:SQLiteData]]) -> Future<View> in
                     
            var projectNames = [String]()
            
            projItems.forEach { projectItem in
                
                for (key, val) in projectItem {
             //       print("key: \(key.name). value: \(val)")
                    
                    var _val: String = "\(val)"
                    
                      /// .replace (/(^")|("$)/g, "")  // this regex trims beginngin and ending quotes too.
                    
                    // FIXME: returns a description of the value rather than the value as a string
                    projectNames.append( _val.trimmingCharacters(in: CharacterSet(charactersIn: "\""))  )
                    
                }
            }
                        
                
            
            return try request.view().render("project-list.html", ProjectListData(projectList: projectNames, projectCount: projectNames.count))
    
        }
        
        
    }
    
    
    
    
    func getProjectDataCsv(_ request: Request) throws -> Future<HTTPResponse> {
    
        let projectId = try request.parameters.next(String.self)
        
        let items = request.withPooledConnection(to: .sqlite) { connection -> Future<[SusScore]> in
            return connection.raw("""
               
            SELECT * FROM `SusScore` WHERE projectId=="\(projectId)";
               
            """).all(decoding: SusScore.self)
                
            // TODO: coudl include data for histogram or just freq dist bins
            
        }

        
        return items.flatMap { (scoreItems: [SusScore]) -> Future<HTTPResponse> in
            let csvPromise = request.eventLoop.newPromise(of: HTTPResponse.self)
            
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
            var response = HTTPResponse(status: .ok, body: scoreItems2.joined(separator: "\n"))
            response.headers.add(name: .contentDisposition, value: "attachment; filename=\"sus-scores-\(projectId).csv\"")
            
            csvPromise.succeed(result: response)

            return csvPromise.futureResult
    
        }
    
    
    }
    
    
    // returns a rendered html view of the project summary.
    func getProjectSumary(_ request: Request) throws -> Future<View> {
        
        struct SusProjectSummary: Codable {
            var projectId: String
            var susScoreMean: Double
            var susScoreMeanFormatted: String
            var observationsCount: Int
            
        }
        
        
      
        let projectId = try request.parameters.next(String.self)
        
        // we will round the calculated score so it is only 1 decimal place.
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.roundingMode = NumberFormatter.RoundingMode.halfUp
        formatter.maximumFractionDigits = 1
        
        
        let items = request.withPooledConnection(to: .sqlite) { connection -> Future<[SusScore]> in
            return connection.raw("""
               
            SELECT * FROM `SusScore` WHERE projectId=="\(projectId)";
               
            """).all(decoding: SusScore.self)
                
            // TODO: could include data for histogram or just freq dist bins
            
        }
        
        return items.flatMap { (scoreItems: [SusScore]) -> Future<View> in
            
            var tmpSum = [Double]()
            
            scoreItems.forEach { (scoreObj: SusScore) in
                tmpSum.append( scoreObj.calcScore() )
            }
            
            let scoresSum = tmpSum.reduce(0, { val1, val2 in
                val1 + val2
            })
            
            return try request.view().render("project-summary.html", SusProjectSummary(projectId: projectId, susScoreMean: scoresSum / Double(scoreItems.count), susScoreMeanFormatted: formatter.string(from: NSNumber(value: scoresSum / Double(scoreItems.count))) ?? ""  ,  observationsCount: scoreItems.count))
            
        }
        
        
    }
    
    
    
    
    // returns a rendered html view of the project summary; with additional information.
    func getProjectListExtended(_ request: Request) throws -> Future<View> {
        
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
        
        
        let items = SusScore.query(on: request).all()
        

        return items.flatMap { (scoreItems: [SusScore]) -> Future<View> in
            
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
            
            return try request.view().render("project-list.html", AllProjectsViewData(projectSummaries: projectSummaries, projectCount: projectSummaries.count) )

        }
        
        
    }


    
    
    
   
    
    func getProjectData(_ request: Request) throws -> Future<[SusScore]> {
        
        let projectId = try request.parameters.next(String.self)
        
    
         // this is how to do raw queries with SQL
         // see https://theswiftwebdeveloper.com/diving-into-vapor-part-4-deeper-into-fluent-30d84e19f114
         return request.withPooledConnection(to: .sqlite) { connection -> Future<[SusScore]> in
             return connection.raw("""
                
             SELECT * FROM `SusScore` WHERE projectId=="\(projectId)";
                
             """).all(decoding: SusScore.self)
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
    
    
    
    
    func deleteProject(_ request: Request) throws -> Future<[SusScore]> {
        
        let projectId = try request.parameters.next(String.self)
        

         // this is how to do raw queries with SQL
         // see https://theswiftwebdeveloper.com/diving-into-vapor-part-4-deeper-into-fluent-30d84e19f114
         return request.withPooledConnection(to: .sqlite) { connection -> Future<[SusScore]> in
             return connection.raw("""
               
               DELETE FROM `SusScore` WHERE projectId=="\(projectId)";
                
               """).all(decoding: SusScore.self)
         }
         
        //return TLXScore.query(on: request).filter(\TLXScore.projectId == projectId).all()
      

    }
    
    
    

    /// Saves a decoded `Sus` to the database.
    func create(_ req: Request) throws -> Future<SusScore> {
        return try req.content.decode(SusScore.self).flatMap { score in
            return score.save(on: req)
        }
    }

    /// Deletes a parameterized `Sus`.
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(SusScore.self).flatMap { score in
            return score.delete(on: req)
        }.transform(to: .ok)
    }
}

