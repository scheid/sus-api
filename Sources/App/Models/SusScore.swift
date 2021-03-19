//
//  SusScore.swift
//  App
//
//  Created by Eischeid, Todd on 2/20/20.
//

import Foundation
import Fluent
import FluentSQLiteDriver
import Vapor

final class SusScore: Model {
    
    // necessary to conform to Fields protocol
    init() {
        

        self.participantId = ""
        self.projectId = ""
        self.dateStamp = Date()

        self.frequently = -1
        self.complex = -1
        self.easyToUse = -1
        self.needSupport = -1
        self.wellIntegrated = -1
        self.inconsistency = -1
        self.mostPeopleLearn = -1
        self.cumbersome = -1
        self.confident = -1
        self.neededToLearn = -1
        
        self.id = UUID()
    }
    
    
    static var schema: String = "susscore"
   
    
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "participant_id")
    var participantId: String
    
    @Field(key: "project_id")
    var projectId: String
    
    @Field(key: "date_stamp")
    var dateStamp: Date
    
    @Field(key: "frequently")
    var frequently: Int
    
    @Field(key: "complex")
    var complex: Int
    
    @Field(key: "easy_to_use")
    var easyToUse: Int
    
    @Field(key: "need_support")
    var needSupport: Int
    
    @Field(key: "well_integrated")
    var wellIntegrated: Int
    
    @Field(key: "inconsistency")
    var inconsistency: Int
    
    @Field(key: "most_people_learn")
    var mostPeopleLearn: Int
    
    @Field(key: "cumbersome")
    var cumbersome: Int
    
    @Field(key: "confident")
    var confident: Int
    
    @Field(key: "needed_to_learn")
    var neededToLearn: Int
    
    
    init(id: UUID? = nil, taskId: String, participantId: String, projectId: String, dateStamp: Date, frequently: Int, complex: Int, easyToUse: Int, needSupport: Int, wellIntegrated: Int, inconsistency: Int, mostPeopleLearn: Int, cumbersome: Int, confident: Int, neededToLearn: Int) {
        
        

        self.participantId = participantId
        self.projectId = projectId
        self.dateStamp = dateStamp

        self.frequently = frequently
        self.complex = complex
        self.easyToUse = easyToUse
        self.needSupport = needSupport
        self.wellIntegrated = wellIntegrated
        self.inconsistency = inconsistency
        self.mostPeopleLearn = mostPeopleLearn
        self.cumbersome = cumbersome
        self.confident = confident
        self.neededToLearn = neededToLearn
        
        self.id = id
    }
    
    
    func csvHeader() -> String {
        return "id,projectId,participantId,frequently,complex,easyToUse,needSupport,wellIntegrated,inconsistency,mostPeopleLearn,cumbersome,confident,neededToLearn,susScore,dateStamp"
    }
    
    func asCsvString() -> String {
        
        return "\(self.id ?? UUID()),\"\(self.projectId)\",\"\(self.participantId)\",\(self.frequently),\(self.complex),\(self.easyToUse),\(self.needSupport),\(self.wellIntegrated),\(self.inconsistency),\(self.mostPeopleLearn),\(self.cumbersome),\(self.confident),\(self.neededToLearn),\(self.calcScore()),\"\(self.dateStamp)\""
    }
    
    func calcScore() -> Double {
    
        // subtract 1 from odd numbered questions
        let _frequently = self.frequently - 1
        let _easyToUse = self.easyToUse - 1
        let _wellIntegrated = self.wellIntegrated - 1
        let _mostPeopleLearn = self.mostPeopleLearn - 1
        let _confident = self.confident - 1
        
        // subtract even responses from 5
        let _complex = 5 - self.complex
        let _needSupport = 5 - self.needSupport
        let _inconsistency = 5 - self.inconsistency
        let _cumbersome = 5 - self.cumbersome
        let _neededToLearn = 5 - self.neededToLearn
        
        // add and multiple sum by 2.5
        let finalScore = Double(_frequently + _easyToUse + _wellIntegrated + _mostPeopleLearn + _confident + _complex + _needSupport + _inconsistency + _cumbersome + _neededToLearn) * Double(2.50)
        
        return finalScore
        
    }
}

/// Allows  to be encoded to and decoded from HTTP messages.
extension SusScore: Content { }

