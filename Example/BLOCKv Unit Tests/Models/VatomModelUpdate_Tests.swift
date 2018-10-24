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

import XCTest
@testable import BLOCKv

class VatomModelUpdate_Tests: XCTestCase {
    
    // MARK: - Properties
    
    var vatomCurrent: VatomModel!
    
    // MARK: - Lifecycle
    
    override func setUp() {
        do {
            vatomCurrent = try self.require(
                try? TestUtility.jsonDecoder.decode(VatomModel.self, from: MockModel.VatomModel.stateUpdateVatom)
            )
        }  catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    override func tearDown() {
        // clean up
        self.vatomCurrent = nil
    }
    
    // MARK: - Tests
    
    /// Tests the `update(applying:)` method on `VatomModel`.
    ///
    /// Specifically tests the root properties.
    func testRootPropertyUpdate() {
        
        // assert before state
        XCTAssertEqual(vatomCurrent.whenModified, DateFormatter.blockvDateFormatter.date(from: "2018-10-15T21:11:25Z"))
        XCTAssertFalse(vatomCurrent.isUnpublished)
        XCTAssertEqual(vatomCurrent.props.parentID, ".")
        XCTAssertEqual(vatomCurrent.props.owner, "21c527fb-8a8b-485b-b549-61b3857easdf")
        XCTAssertEqual(vatomCurrent.props.notifyMessage , "")
        XCTAssertTrue(vatomCurrent.props.isTransferable)
        XCTAssertTrue(vatomCurrent.props.isTradeable)
        XCTAssertTrue(vatomCurrent.props.isDropped)
        XCTAssertTrue(vatomCurrent.props.isAcquirable)
        XCTAssertTrue(vatomCurrent.props.isRedeemable)
        XCTAssertTrue(vatomCurrent.props.isDisabled)
        XCTAssertEqual(vatomCurrent.props.numberDirectClones, 2)
        XCTAssertEqual(vatomCurrent.props.tags, [])
        XCTAssertEqual(vatomCurrent.props.transferredBy, "68103f27-b8e8-490d-8678-c045812easdf")
        XCTAssertEqual(vatomCurrent.props.clonedFrom, "2c2b5435-210b-41d1-abab-1e9510b5asdf")
        XCTAssertEqual(vatomCurrent.props.cloningScore, 0.5)
        XCTAssertEqual(vatomCurrent.props.isInContract, false)
        XCTAssertEqual(vatomCurrent.props.inContractWith, "")
        XCTAssertEqual(vatomCurrent.props.geoPosition.coordinates, [0,0])
        XCTAssertEqual(vatomCurrent.props.visibility.type, "owner")
        XCTAssertEqual(vatomCurrent.props.commerce.pricing.pricingType, "Fixed")
        XCTAssertEqual(vatomCurrent.props.commerce.pricing.currency, "")
        XCTAssertEqual(vatomCurrent.props.commerce.pricing.price, "")
        XCTAssertEqual(vatomCurrent.props.commerce.pricing.validFrom, "*")
        XCTAssertEqual(vatomCurrent.props.commerce.pricing.validThrough, "*")
        XCTAssertEqual(vatomCurrent.props.commerce.pricing.isVatIncluded, false)

        XCTAssertEqual(vatomCurrent.private?["array"], [1, 2, 3])
        XCTAssertEqual(vatomCurrent.eos?["fields"]?["lighton"]?["value"], false)

        // set the root properties to change
        let newProperties: JSON = [
            "when_modified": "2019-10-15T21:11:25Z",
            "unpublished": true,
            "vAtom::vAtomType": [
                "parent_id": "8499DC2E-4844-4E60-8899-F42D03A74C41",
                "owner": "440153F9-C7F3-4D25-8E3D-BF1F0FCCBAE2",
                "notify_msg": "Hello, World!",
                "transferable": false,
                "tradeable": false,
                "dropped": false,
                "acquirable": false,
                "redeemable": false,
                "disabled": false,
                "num_direct_clones" : 3,
                "tags": ["fun", "sun"],
                "transferred_by": "BEA77DEB-CDE4-4921-9CD9-5D3B2336BFFD",
                "cloned_from": "0D1453DE-9495-4ADA-8BFF-A77CEEC3F5A4",
                "cloning_score": 1,
                "in_contract": true,
                "in_contract_with": "me",
                "geo_pos": [
                    "coordinates": [
                        18.68768,
                        -33.824017
                    ]
                ],
                "visibility": [
                    "type": "public"
                ],
                "commerce": [
                    "pricing": [
                        "pricingType": "Fixed",
                        "value": [
                            "currency": "ZAR",
                            "price": "1.00",
                            "valid_from": "2019-10-15T21:11:25Z",
                            "valid_through": "2019-19-15T21:11:25Z",
                            "vat_included": true
                        ]
                    ]
                ]
            ],
            "private": [
                "array": [4, 5, 6]
            ],
            "eos": [
                "fields": [
                    "lighton": [
                        "value": true
                    ]
                ]
            ],
            "eth": [
                "wallet": [
                    "address" : "76FA18D7-0426-4335-9ADE-A59DF3C75613"
                ]
            ]
        ]
        
        // create fake state update event
        let stateUpdate = WSStateUpdateEvent(eventId: "1",
                                             operation: "mock",
                                             vatomId: "49d9229d-a380-40ac-9c22-asdf9664bd63",
                                             vatomProperties: newProperties,
                                             timestamp: Date())
        
        do {
            // ensure the update did not return nil
            let vatomUpdated = try self.require(vatomCurrent.updated(applying: stateUpdate))
            
            // assert after state
            XCTAssertEqual(vatomUpdated.whenModified,
                           DateFormatter.blockvDateFormatter.date(from: "2019-10-15T21:11:25Z"))
            XCTAssertTrue(vatomUpdated.isUnpublished)
            XCTAssertEqual(vatomUpdated.props.parentID, "8499DC2E-4844-4E60-8899-F42D03A74C41")
            XCTAssertEqual(vatomUpdated.props.owner, "440153F9-C7F3-4D25-8E3D-BF1F0FCCBAE2")
            XCTAssertEqual(vatomUpdated.props.notifyMessage, "Hello, World!")
            XCTAssertFalse(vatomUpdated.props.isTransferable)
            XCTAssertFalse(vatomUpdated.props.isTradeable)
            XCTAssertFalse(vatomUpdated.props.isDropped)
            XCTAssertFalse(vatomUpdated.props.isAcquirable)
            XCTAssertFalse(vatomUpdated.props.isRedeemable)
            XCTAssertFalse(vatomUpdated.props.isDisabled)
            XCTAssertEqual(vatomUpdated.props.numberDirectClones, 3)
            XCTAssertEqual(vatomUpdated.props.tags, ["fun", "sun"])
            XCTAssertEqual(vatomUpdated.props.transferredBy, "BEA77DEB-CDE4-4921-9CD9-5D3B2336BFFD")
            XCTAssertEqual(vatomUpdated.props.clonedFrom, "0D1453DE-9495-4ADA-8BFF-A77CEEC3F5A4")
            XCTAssertEqual(vatomUpdated.props.cloningScore, 1)
            XCTAssertEqual(vatomUpdated.props.isInContract, true)
            XCTAssertEqual(vatomUpdated.props.inContractWith, "me")
            // FIXME: A convertion error is occurring moving from float to double.
            //XCTAssertEqual(vatomUpdated.props.geoPosition.coordinates, [18.68768, -33.824017])
            XCTAssertEqual(vatomUpdated.props.visibility.type, "public")
            
            XCTAssertEqual(vatomUpdated.props.commerce.pricing.pricingType, "Fixed")
            XCTAssertEqual(vatomUpdated.props.commerce.pricing.currency, "ZAR")
            XCTAssertEqual(vatomUpdated.props.commerce.pricing.price, "1.00")
            XCTAssertEqual(vatomUpdated.props.commerce.pricing.validFrom, "2019-10-15T21:11:25Z")
            XCTAssertEqual(vatomUpdated.props.commerce.pricing.validThrough, "2019-19-15T21:11:25Z")
            XCTAssertEqual(vatomUpdated.props.commerce.pricing.isVatIncluded, true)
           
            let privateSection = try self.require(vatomUpdated.private)
            XCTAssertEqual(privateSection["array"], [4, 5, 6])
            XCTAssertEqual(vatomUpdated.eos?["network"], "testnet")
            XCTAssertEqual(vatomUpdated.eos?["fields"]?["lighton"]?["value"], true) // ensure value change
            
            //TODO: Find out if ETH section may be updated after

        }  catch {
            XCTFail(error.localizedDescription)
        }
        
    }
    
}
