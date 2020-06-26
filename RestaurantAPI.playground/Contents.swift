import UIKit

class Restaurant: Codable {
    
    // MARK: - Properties
    let restaurantID: String
    let name: String
    let coordinates: [String : Float]
    let categories: [[String : String]]
    let rating: Float
//    let hours: Hours?
    
    // Hours is type [[String : Any]] so need to use struct instead
//    struct Hours: Codable {
//        let openNow: Bool
//        let open: [[String : Int]]
//
//        enum CodingKeys: String, CodingKey {
//            case open, openNow = "is_open_now"
//        }
//    }
//
    enum CodingKeys: String, CodingKey {
        case name, coordinates, categories, rating, restaurantID = "id"
    }
}

struct RestaurantTopLevelDictionary: Codable {
    let businesses: [Restaurant]
}

struct yelpStrings {
    static let baseURLString = "https://api.yelp.com/v3/businesses"
    static let authHeader = "Authorization"
    static let apiKeyValue = "Bearer R_hx8BUmF2jCHNXqEU8T2_9JubC4CP5ZW2jNxXN0NqFKNd9De8vcX_YAlAKRa3At1OwwSnQYd8VoOg4WGKqli0eJDSF8mA4BdNLktpDMoxDUWJhrTF99eRuJ-yjyXnYx"
    static let methodValue = "GET"
    static let searchPath = "search"
    static let termKey = "term"
    static let termValue = "restaurants"
    static let categoriesKey = "categories"
    static let longitudeKey = "longitude"
    static let latitudeKey = "latitude"
}


let sampleRestaurantID = "svJWwW0ilssyqk_UML0mUg"


func fetchRestaurantsWithID(restaurantID: String, completion: @escaping (Restaurant?) -> Void) {
    // 1 - URL setup
    var request = URLRequest(url: URL(string: "\(yelpStrings.baseURLString)/\(restaurantID)")!, timeoutInterval: Double.infinity)
    request.addValue(yelpStrings.apiKeyValue, forHTTPHeaderField: yelpStrings.authHeader)
    request.httpMethod = yelpStrings.methodValue
    print(request)
    
    // 2 - Data task
    URLSession.shared.dataTask(with: request) { data, _, error in
        
        // 3 - Error Handling
        if let error = error {
            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            return completion(nil)
        }
        
        // 4 - check for data
        guard let data = data else { return completion(nil)}
        
        // 5 - Decode data
        do {
            let restaurant = try JSONDecoder().decode(Restaurant.self, from: data)
            return completion(restaurant)
        } catch {
            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            return completion(nil)
        }
    }.resume()
}

fetchRestaurantsWithID(restaurantID: sampleRestaurantID) { (restaurant) in
    print(restaurant)
}
