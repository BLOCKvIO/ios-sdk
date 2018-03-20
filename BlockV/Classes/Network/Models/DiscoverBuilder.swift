//
//  DiscoverBuilder.swift
//  BlockV
//
//  Created by Cameron McOnie on 2018/03/20.
//

import Foundation



//protocol DiscoverBuildable {
//
//    func setScope(field: String, value: String) -> Self
//
//    func addFilter(field: String, value: String, operation: FilterOperation, combineOperation: CombineOperation) -> Self
//
//    func addReturn() -> Self
//
//}
//
//class DiscoverBuilder: DiscoverBuildable {
//
//    private var scope: [String : String]?
//    private var filters:
//
//    func setScope(field: String, value: String) -> Self {
//        <#code#>
//    }
//
//    func addFilter(field: String, value: String, operation: FilterOperation, combineOperation: CombineOperation) -> Self {
//        <#code#>
//    }
//
//    func addReturn() -> Self {
//        <#code#>
//    }
//
//    public struct FilterElement: Equatable {
//
//        /// Filter operator
//        public enum FilterOperator: String {
//            case equal = "Eq"
//            case match = "Match" // Match is a special case, allowing for a regex query in the value field with the wildcard *
//        }
//
//        /// Filter combine operator
//        public enum CombineOperator: String {
//            case and = "And"
//            case or  = "Or"
//        }
//
//        public let field: String
//        public let filterOperator: FilterOperator
//        public let value: String
//        public let combineOperator: CombineOperator
//
//    }
//
//}
//
//extension

