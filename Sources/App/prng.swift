//
//  Created by Todd Eischeid on 11/14/16.
//  An abstraction layer for random number generation
//

import Foundation


open class Prng {
    
    var prngGenerator: Xshiro256plus


    public init(seed: [UInt64]?) {

        
        
        if let x = seed {
           self.prngGenerator = Xshiro256plus(seed: x)
        } else {
            self.prngGenerator = Xshiro256plus(seed: [012703, 31205, 090806, UInt64(Date().timeIntervalSince1970)])
        }
        
        // make first few calls to better acheive random values; first few may not be reliable.
        self.prngGenerator.next()
        self.prngGenerator.next()
        self.prngGenerator.next()
        self.prngGenerator.next()
        
        
    }
    
    
    // just a hex string; use for whatever you wish
    public func getHexString(length: Int) -> String {
    
        var result: [String] = [String]()
        let digits = ["0", "1", "2", "3", "4", "5" ,"6" ,"7" ,"8" ,"9", "a", "b", "c", "d", "e", "f"]
        
            for _ in 0..<length {
                result.append(digits[self.randInt(15)])
            }
        
        return result.joined()
    }
        

    
    //you can use this one if you need to  generate a predictable/consistent sequence of uuid's , because this will use the random generator that is seeded
    // In other types of applications, where you needed security, using this would be an undesired use case, but for some of our generation of hypothetical values (patient records),
    // we may need to be able to reproduce the same value sequences, including 'random' id's
    public func uuid() -> String {
    
        let digit = ["8", "9", "A", "B"]
        let result = "\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))-\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))-4\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))-\(digit[self.randInt(3)])\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))-\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))\(String(Int(self.uxRand()*16.0), radix:16))"
        return result
    
        //swift native way to do this is: UUID().uuidString.lowercased()
    }

    //  this is the base random generator function; this function is the abstaction for whatever OS level PRNG you are using.
    public func uxRand() -> Double {
        
        return self.prngGenerator.next()

    }
    
    public func randInt(_ maxVal: Int) -> Int {
        
       
        return  Int( (self.uxRand() * Double(maxVal)).rounded() )
        
    }
    
    public func randInt(minVal: Int, maxVal: Int) -> Int {
        
        return  minVal + Int( (self.uxRand() * Double(maxVal - minVal)).rounded() )

    }

    public func randDouble(minVal: Double, maxVal: Double) -> Double {
        
        return  minVal +  self.uxRand() * (maxVal - minVal)
    }
    
    //the probability param specifies the probability that true value will be returned.
    public func randBernoulli(_ probability: Double = 0.5) -> Bool {
        
        return (self.uxRand() <= probability)
        
    }


    //essentially adds some noise to a value; useful when trying to make values a bit messy; more realistic for certain things.
    public func jitter(value: Int, maxJitterAmount: Int) -> Int {
        return self.randInt(minVal: value - maxJitterAmount, maxVal: value + maxJitterAmount )
    }


    //same, for doubles
    public func jitter(value: Double, maxJitterAmount: Double) -> Double {

        //TODO: need a randDouble func to make this work.
        return self.randDouble(minVal: value - maxJitterAmount, maxVal: value + maxJitterAmount )
    }



    //pass this an array of integers, like indices of an array, and this will choose the specified number
    // of random items from that array; like picking n cards from a deck. it will return the randomly chosen items
    //could easily extend this to array of strings, etc. more complex arrays would be trickier
    public func getRandomItems(src: [Int], itemCountToGet: Int) -> [Int] {
    
        var tmpSrc = src
        var tmpIdx: Int = 0
        var result: [Int] = []

        //TODO: may want to throw here; these conditions are bad input.  or maybe just returning empty is ok.
        if src.count == 0 { return result }
        if itemCountToGet > src.count { return result }
        
        if itemCountToGet > 1 {
            for _ in 0..<itemCountToGet {
                tmpIdx = randInt(minVal: 0, maxVal: tmpSrc.count - 1)
                result.append( tmpSrc.remove(at: tmpIdx) )
            }
        } else {
            tmpIdx = randInt(minVal: 0, maxVal: tmpSrc.count - 1)
            result.append( tmpSrc[tmpIdx] )
        }
        
        return result
    }


    //will assume you want to choose from a sequentially numbered, zero-based array, which is what the indices of an array woudl be.
    // srcCount tells the function the desired size of the source array. 
    // if your goal is to choose items from an array, then just pass the array size into srcCount, and this function will give 
    // you randomly chosen array indices to use
    public func getRandomItems(srcCount: Int, itemCountToGet: Int) -> [Int] {

        if srcCount > 1 {
            let tmpInput = Array(0...(srcCount-1))
            return getRandomItems(src: tmpInput, itemCountToGet: itemCountToGet)
        } else {
            
            if srcCount > 0 {
                return [0]
            } else {
                return []
            }
            
        }
        
        
    }


// picks a random item from a set adhering to the weighting array passed in.

//NOTE that this will return an *array index* for you to use in your actual array. Your items array is assumed to be the same length as the weights array, and each 
// value in your weights array corresponds to the probability of the same-index item in your values array.
// by returning a simple array index, this gives you max flexibility in the array that you use the random item for.
// the weights param represents proportions of the total of each item's chance of being selected; the weights should add up to 1.0

    public func getRandomItemWeighted(weights: [Double]) -> Int {

        let rndVal = uxRand()
        var weightCum: Double = 0.0
        var result: Int = -1

        for i in 0...(weights.count - 1) {

            if (rndVal > weightCum) && (rndVal <= (weightCum + weights[i])) {
                result = i
                break
            }

            weightCum += weights[i]

        }

        return result

    }


      

 
    public func getDobForAge(ageLower: Int, ageUpper: Int) -> Date {
        
        
        let currDate = Date()
        let cal = Calendar.current
        
        var currDateComponents1 = cal.dateComponents([.hour, .minute, .day, .month, .year], from: currDate)
        var currDateComponents2 = cal.dateComponents([.hour, .minute, .day, .month, .year], from: currDate)
        
        currDateComponents1.year =  currDateComponents1.year! - ageLower
        currDateComponents2.year = currDateComponents2.year! - ageUpper
        
        let newDate1 = cal.date(from: currDateComponents1)
        let newDate2 = cal.date(from: currDateComponents2)
        
        
        //TODO: these else blocks should probably throw
        
        guard let d1 = newDate1 else {
            //FileLogger.logIt("ERROR", "could not create date for ageLower")
            return Date()
        }
        
        guard let d2 = newDate2 else {
            //FileLogger.logIt("ERROR", "could not create date for ageUpper")
            return Date()
        }
 
        //now, get a random epoch value within the desired range.
        let rndEpoch = randDouble(minVal: d1.timeIntervalSince1970, maxVal: d2.timeIntervalSince1970)
  
        return Date(timeIntervalSince1970: rndEpoch)
        
        
    }


}
