//
//  File.swift
//  
//
//  Created by Eischeid, Todd on 3/18/21.
//

import Foundation
import Fluent


struct CreateTable: Migration {
    
    
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            
            print("running prepare for 'susscore'; creating table. . .")
            return database.schema("susscore")
                .id()
                .field("participant_id", .string, .required)
                .field("project_id", .string, .required)
                .field("date_stamp", .date, .required)
                .field("frequently", .int, .required)
                .field("complex", .int, .required)
                .field("easy_to_use", .int, .required)
                .field("need_support", .int, .required)
                .field("well_integrated", .int, .required)
                .field("inconsistency", .int, .required)
                .field("most_people_learn", .int, .required)
                .field("cumbersome", .int, .required)
                .field("confident", .int, .required)
                .field("needed_to_learn", .int, .required)
                .create()

        }
       
    
    
        func revert(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("susscore").delete()       }
    
    
}
