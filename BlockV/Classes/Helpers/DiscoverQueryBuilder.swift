//
//  BlockV AG. Copyright (c) 2018, all rights reserved.
//
//  Licensed under the BlockV SDK License (the "License"); you may not use this file or
//  the BlockV SDK except in compliance with the License accompanying it. Unless
//  required by applicable law or agreed to in writing, the BlockV SDK distributed under
//  the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
//  ANY KIND, either express or implied. See the License for the specific language
//  governing permissions and limitations under the License.
//

import Foundation

/// Builds discover query request payload.
///
/// This object simplifies the construction of an otherwise involved discover
/// query payload.
public class DiscoverQueryBuilder {
    
    // MARK: - Enums
    
    /// Scope key
    public enum ScopeKey: String {
        case owner             = "vAtom::vAtomType.owner"
        case template          = "vAtom::vAtomType.template"
        case templateVariation = "vAtom::vAtomType.template_variation"
        case acquirable        = "vAtom::vAtomType.acquirable"
        case parentID          = "vAtom::vAtomType.parent_id"
    }
    
    /// Models the options for the structure and contents of the query's response.
    public enum ResultType: String {
        case payload = "*"
        case count   = "count"
    }
    
    // MARK: - Properties
    
    /// A scope is fast due to db indexing.
    private var scope: [String : String] = [:]
    
    /// Filter elements are slower in-memory filters.
    private var filters: [FilterElement] = []
    
    /// Alters the structure of the response.
    ///
    /// Defaults to returning the full payload.
    private var resultStructure: [String : Any] = ["type": ResultType.payload.rawValue, "fields": []]
    
    // MARK: - Init
    
    public init() { }
    
    // MARK: - Builders
    
    /// Set the scope to the owner.
    public func setScopeToOwner() {
        self.scope = ["key" : ScopeKey.owner.rawValue, "value": "$currentuser"]
    }
    
    /// Sets the scope of the search query.
    ///
    /// - Parameters:
    ///   - scope: Search field.
    ///   - value: Value for lookup.
    public func setScope(scope: ScopeKey, value: String) {
        self.scope = ["key" : scope.rawValue, "value": value]
    }
    
    /// Adds a defined filter element to the query.
    ///
    /// - Parameters:
    ///   - field: Search field.
    ///   - filterOperator: The operator to apply between the `field` and `value` items.
    ///   - value: Value for lookup.
    ///   - combineOperator: Controls the boolean operator applied between this element and the other filter elements.
    public func addDefinedFilter(forField field: FilterElement.Field, filterOperator: FilterElement.FilterOperator, value: String, combineOperator: FilterElement.CombineOperator) {
        
        // create element
        let filter = FilterElement(field: field, filterOperator: filterOperator, value: value, combineOperator: combineOperator)
        self.filters.append(filter)
        
    }
    
    /// Adds a custom filter element to the query.
    ///
    /// This method provides you with full control over the contents of the fileter element.
    ///
    /// - Parameters:
    ///   - field: Lookup field.
    ///   - filterOperator: The operator to apply between the `field` and `value` items.
    ///   - value: Value associated with the `field`.
    ///   - combineOperator: Controls the boolean operator applied between this element and the other filter elements.
    public func addCustomFilter(forField field: String, filterOperator: String, value: String, combineOperator: String) {
        
        // create element
        let filter = FilterElement(field: field, filterOperator: filterOperator, value: value, combineOperator: combineOperator)
        self.filters.append(filter)
        
    }
    
    /// Optionally set the return structure.
    public func setReturn(type: ResultType, fields: [String]) {
        self.resultStructure = ["type": type.rawValue, "fields": fields]
    }
    
}

// MARK: - Dictionary Codable

extension DiscoverQueryBuilder: DictionaryCodable {
    
    public func toDictionary() -> [String : Any] {
        
        var payload: [String : Any] = [:]
        
        payload["scope"] = self.scope
        let filterElems = self.filters.map { $0.toDictionary() } // map the filters to dictionaries
        payload["filters"] = [["filter_elems": filterElems]] // filters is an array, the first element is 
        payload["return"] = self.resultStructure
        
        return payload
        
    }

}

// MARK: - FilterElement

extension DiscoverQueryBuilder {
    
    /// Filter element of the queury
    public struct FilterElement: DictionaryCodable {
        
        /// Filter operator
        public enum FilterOperator: String {
            case equal          = "Eq"
            case greaterThan    = "Gt"
            case greaterOrEqual = "Ge"
            case lessThan       = "Lt"
            case lessOrEqual    = "Le"
            case notEqual       = "Ne"
            case match          = "Match" // <- Match is a special case, allowing for a regex query in the value field
        }
        
        /// Filter field
        public enum Field: String {
            case id                  = "id"
            case whenCreated         = "when_created"
            case whenModified        = "when_modified"
            case parentID            = "vAtom::vAtomType.parent_id"
            case owner               = "vAtom::vAtomType.owner"
            case author              = "vAtom::vAtomType.author"
            case templateID          = "vAtom::vAtomType.template"
            case templateVariationID = "vAtom::vAtomType.template_variation"
            case dropped             = "vAtom::vAtomType.dropped"
            case transferable        = "vAtom::vAtomType.transferable"
            case acquirable          = "vAtom::vAtomType.acquirable"
            case category            = "vAtom::vAtomType.category"
            case title               = "vAtom::vAtomType.title"
        }
        
        /// Filter combine operator
        public enum CombineOperator: String {
            case and = "And"
            case or  = "Or"
        }
        
        // MARK: Properties
        
        // The four items that make up a filter element.
        private let field: String
        private let filterOperator: String
        private let combineOperator: String
        private let value: String
        
        // MARK: Init
        
        init(field: Field, filterOperator: FilterOperator, value: String, combineOperator: CombineOperator) {
            self.field = field.rawValue
            self.filterOperator = filterOperator.rawValue
            self.value = value
            self.combineOperator = combineOperator.rawValue
        }
        
        init(field: String, filterOperator: String, value: String, combineOperator: String) {
            self.field = field
            self.filterOperator = filterOperator
            self.value = value
            self.combineOperator = combineOperator
        }
        
        // MARK: DictionaryCodable
        
        public func toDictionary() -> [String : Any] {
            return [
                "field": field,
                "filter_op": filterOperator,
                "value": value,
                "bool_op": combineOperator
            ]
        }
        
    }
    
}


