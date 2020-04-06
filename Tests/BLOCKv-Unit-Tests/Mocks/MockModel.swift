//
//  BLOCKv AG. Copyright (c) 2018, all rights reserved.
//
//  Licensed under the BLOCKv SDK License (the "License"); you may not use this file or
//  the BLOCKv SDK except in compliance with the License accompanying it. Unless
//  required by applicable law or agreed to in writing, the BLOCKv SDK distributed under
//  the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
//  ANY KIND, either express or implied. See the License for the specific language
//  governing permissions and limitations under the License.
//

import Foundation

public enum MockModel {

    public enum FaceModel {
        
        public static let nativeSpriteSheet = """
        {
                "id": "C4A795E4-26B7-43FF-B761-14AC5156BB52",
                "template": "vatomic.prototyping::test_vatom",
                "meta": {
                    "created_by": "BLOCKv Backend",
                    "when_created": "2019-09-11T19:26:38Z",
                    "modified_by": "BLOCKv Backend",
                    "when_modified": "2019-09-12T10:31:29Z",
                    "data_type": "v1::FaceType"
                },
                "properties": {
                    "display_url": "native://sprite-sheet",
                    "package_url": ".",
                    "constraints": {
                        "bluetooth_le": false,
                        "contact_list": false,
                        "gps": false,
                        "three_d": false,
                        "view_mode": "icon",
                        "platform": "generic",
                        "quality": "high"
                    },
                    "resources": [],
                    "config": {
                        "animation_rules": [
                            {
                                "on": "start",
                                "play": "cheer"
                            },
                            {
                                "on": "state",
                                "play": "run",
                                "target": "private.state.value",
                                "value": 1
                            },
                            {
                                "on": "state",
                                "play": "punch",
                                "target": "private.state.value",
                                "value": 2
                            },
                            {
                                "on": "state",
                                "play": "look_around",
                                "target": "private.state.value",
                                "value": 3
                            },
                            {
                                "on": "state",
                                "play": "fall",
                                "target": "private.state.value",
                                "value": 4
                            },
                            {
                                "on": "state",
                                "play": "get_up",
                                "target": "private.state.value",
                                "value": 5
                            },
                            {
                                "on": "state",
                                "play": "kick",
                                "target": "private.state.value",
                                "value": 6
                            },
                            {
                                "on": "state",
                                "play": "shrug",
                                "target": "private.state.value",
                                "value": 7
                            },
                            {
                                "on": "state",
                                "play": "jump",
                                "target": "private.state.value",
                                "value": 8
                            },
                            {
                                "on": "state",
                                "play": "cheer",
                                "target": "private.state.value",
                                "value": 9
                            },
                            {
                                "on": "state",
                                "play": "run_backwards",
                                "target": "private.state.value",
                                "value": 10
                            },
                            {
                                "on": "state",
                                "play": "run_loop",
                                "target": "private.state.value",
                                "value": 11
                            },
                            {
                                "on": "state",
                                "play": "fall_backwards_loop",
                                "target": "private.state.value",
                                "value": 12
                            },
                            {
                                "on": "state",
                                "play": "freeze_start",
                                "target": "private.state.value",
                                "value": 13
                            },
                            {
                                "on": "state",
                                "play": "freeze_run",
                                "target": "private.state.value",
                                "value": 14
                            },
                            {
                                "on": "state",
                                "play": "freeze_end",
                                "target": "private.state.value",
                                "value": 15
                            },
                            {
                                "on": "state",
                                "play": "out_of_bounds",
                                "target": "private.state.value",
                                "value": 16
                            },
                            {
                                "on": "click",
                                "play": "run",
                                "target": ""
                            },
                            {
                                "on": "click",
                                "play": "jump",
                                "target": "run"
                            },
                            {
                                "on": "animation-complete",
                                "play": "cheer",
                                "target": "kick"
                            }
                        ],
                        "sprite_animations": {
                            "animations": [
                                {
                                    "frame_end": 12,
                                    "frame_start": 0,
                                    "name": "run"
                                },
                                {
                                    "frame_end": 20,
                                    "frame_start": 12,
                                    "name": "punch"
                                },
                                {
                                    "frame_end": 27,
                                    "frame_start": 20,
                                    "name": "look_around"
                                },
                                {
                                    "frame_end": 34,
                                    "frame_start": 27,
                                    "name": "fall"
                                },
                                {
                                    "frame_end": 41,
                                    "frame_start": 34,
                                    "name": "get_up"
                                },
                                {
                                    "frame_end": 48,
                                    "frame_start": 41,
                                    "name": "kick"
                                },
                                {
                                    "frame_end": 56,
                                    "frame_start": 48,
                                    "name": "shrug"
                                },
                                {
                                    "frame_end": 68,
                                    "frame_start": 56,
                                    "name": "jump"
                                },
                                {
                                    "frame_end": 75,
                                    "frame_start": 68,
                                    "name": "cheer"
                                },
                                {
                                    "backwards": true,
                                    "frame_end": 12,
                                    "frame_start": 0,
                                    "name": "run_backwards"
                                },
                                {
                                    "frame_end": 12,
                                    "frame_start": 0,
                                    "loop": true,
                                    "name": "run_loop"
                                },
                                {
                                    "backwards": true,
                                    "frame_end": 34,
                                    "frame_start": 27,
                                    "loop": true,
                                    "name": "fall_backwards_loop"
                                },
                                {
                                    "frame_start": 0,
                                    "name": "freeze_start"
                                },
                                {
                                    "frame_start": 12,
                                    "name": "freeze_run",
                                    "slide_in": true
                                },
                                {
                                    "frame_start": 75,
                                    "name": "freeze_end",
                                    "slide_in": true
                                },
                                {
                                    "frame_end": 100,
                                    "frame_start": -1,
                                    "name": "out_of_bounds"
                                }
                            ],
                            "frame_count": 76,
                            "frame_height": 360,
                            "frame_rate": 8,
                            "frame_width": 331
                        }
                    }
                }
            }
        """.data(using: .utf8)!

        public static let nativeGenericIcon = """
            {"id":"48476b21-a4cf-45b6-a2f3-9a9c7b491237","template":"vatomic.prototyping::Drone2","meta":{"created_by":"BLOCKv Backend","when_created":"2018-07-25T12:58:24Z","modified_by":"","when_modified":"2018-07-25T12:58:24Z","data_type":"v1::FaceType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"display_url":"native://generic-3d","package_url":".","constraints":{"bluetooth_le":false,"contact_list":false,"gps":false,"three_d":false,"view_mode":"icon","platform":"generic","quality":"high"},"resources":["ActivatedImage"]}}
            """.data(using: .utf8)!

        public static let webGenericFullscreen = """
            {"id":"856a8bc5-ada5-4158-840f-370d27171234c","template":"vatomic.prototyping::Invitation::v1","meta":{"created_by":"BLOCKv Backend","when_created":"2018-05-09T02:50:38Z","modified_by":"BLOCKv Backend","when_modified":"2018-05-10T14:35:21Z","data_type":"v1::FaceType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"display_url":"https://somewebsite.face.index.html","package_url":".","constraints":{"bluetooth_le":false,"contact_list":false,"gps":false,"three_d":false,"view_mode":"fullscreen","platform":"generic","quality":"high"},"resources":["CardBackground"]}}
            """.data(using: .utf8)!
        
        public static let nativeImageV2 = """
        {"id":"c0231a61-fea4-4110-925c-9998b8812345","template":"vatomic.prototyping::bridge-tester::unit-test","meta":{"created_by":"BLOCKv","when_created":"2020-04-02T17:54:33Z","modified_by":"","when_modified":"2020-04-02T17:54:33Z","data_type":"v1::FaceType"},"properties":{"display_url":"native://image","package_url":".","constraints":{"bluetooth_le":false,"contact_list":false,"gps":false,"three_d":false,"view_mode":"icon","platform":"generic","quality":"high"},"resources":null}}
        """.data(using: .utf8)!

    }

    public enum VatomModel {

        public static let basicVatom = """
            {"id":"DD46C2D0-8596-4EEC-8F48-8987542E26A9","when_created":"2018-12-10T12:55:08Z","when_modified":"2019-05-21T07:21:06Z","when_added":"2019-05-21T07:21:06Z","vAtom::vAtomType":{"parent_id":".","publisher_fqdn":"fun.proto","root_type":"vAtom::vAtomType::DefinedFolderContainerType","owner":"D4D80A22-27F2-4F58-9A40-DC083F3B5437","author":"02A49EDC-9870-4634-8EAF-ADCD784C4156","template":"fun.proto::AnimatedCrate::v1","template_variation":"fun.proto::AnimatedCrate::v1::AvatarCrate::v1","notify_msg":"","title":"Avatar Crate","description":"Male Avatar","disabled":false,"category":"Gifts","tags":[],"transferable":true,"acquirable":true,"tradeable":false,"transferred_by":"8D987258-2853-4936-AF83-B29502874E14","cloned_from":"","cloning_score":0,"in_contract":false,"redeemable":false,"in_contract_with":"","commerce":{"pricing":{"pricingType":"Fixed","value":{"currency":"","price":"","valid_from":"*","valid_through":"*","vat_included":false}}},"states":[{"name":"Activated","value":{"type":"boolean","value":"true"},"on_state_change":{"reactor":""}}],"resources":[{"name":"ActivatedImage","resourceType":"ResourceTypes::Image::PNG","value":{"resourceValueType":"ResourceValueType::URI","value":"http://somedomain/resources/a.png"}},{"name":"CoverImage","resourceType":"ResourceTypes::Image::PNG","value":{"resourceValueType":"ResourceValueType::URI","value":"http://somedomain/resources/b.mp4"}},{"name":"Video","resourceType":"ResourceTypes::Video::MP4","value":{"resourceValueType":"ResourceValueType::URI","value":"http://somedomain/resources/c.glb"}}],"visibility":{"type":"owner","value":"*"},"num_direct_clones":0,"geo_pos":{"type":"Point","coordinates":[0,0]},"dropped":false,"age":0,"child_policy":[{"template_variation":"fun.proto::CombineCard::v1::Avatar::v1","creation_policy":{"auto_create":"create_new","auto_create_count":1,"auto_create_count_random":false,"weighted_choices":null,"policy_count_min":0,"policy_count_max":1,"enforce_policy_count_min":false,"enforce_policy_count_max":true},"count":0},{"template_variation":"fun.proto::Image::v1::AvatarHairIcon::v1","creation_policy":{"auto_create":"create_new","auto_create_count":1,"auto_create_count_random":false,"weighted_choices":null,"policy_count_min":0,"policy_count_max":1,"enforce_policy_count_min":false,"enforce_policy_count_max":true},"count":0},{"template_variation":"fun.proto::Image::v1::AvatarMaskIcon::v1","creation_policy":{"auto_create":"create_new","auto_create_count":1,"auto_create_count_random":false,"weighted_choices":null,"policy_count_min":0,"policy_count_max":1,"enforce_policy_count_min":false,"enforce_policy_count_max":true},"count":0},{"template_variation":"fun.proto::Image::v1::AvatarSuitIcon::v1","creation_policy":{"auto_create":"create_new","auto_create_count":1,"auto_create_count_random":false,"weighted_choices":null,"policy_count_min":0,"policy_count_max":1,"enforce_policy_count_min":false,"enforce_policy_count_max":true},"count":0}],"child_return_policy":null},"private":{"array":[1,2,3],"boolean":true,"color":"#82b92c","null":null,"number":123,"object":{"a":"b","c":"d","e":"f"},"string":"Hello World"},"unpublished":false,"version":"v1::vAtomType","sync":5}
            """.data(using: .utf8)!

        public static let stateUpdateVatom = """
            {"id":"49d9229d-a380-40ac-9c22-asdf9664bd63","when_created":"2018-10-05T07:36:30Z","when_added":"2018-10-15T21:11:25Z","when_modified":"2018-10-15T21:11:25Z","vAtom::vAtomType":{"parent_id":".","publisher_fqdn":"vatomic.prototyping","root_type":"vAtom::vAtomType","owner":"21c527fb-8a8b-485b-b549-61b3857easdf","author":"715e0e66-3b18-4719-a927-3e06221easdf","template":"vatomic.prototyping::HeinekenProgress::v1","template_variation":"vatomic.prototyping::HeinekenProgress::v1::HeinekenProgressVatom::v2","notify_msg":"","title":"Heineken Progress Vatom","description":"A beer that must be shared 4 times before being redeemable","disabled":true,"category":"Food & Drink","tags":[],"transferable":true,"acquirable":true,"tradeable":true,"transferred_by":"68103f27-b8e8-490d-8678-c045812easdf","cloned_from":"2c2b5435-210b-41d1-abab-1e9510b5asdf","cloning_score":0.5,"in_contract":false,"redeemable":true,"in_contract_with":"","commerce":{"pricing":{"pricingType":"Fixed","value":{"currency":"","price":"","valid_from":"*","valid_through":"*","vat_included":false}}},"states":[{"name":"Activated","value":{"type":"boolean","value":"true"},"on_state_change":{"reactor":""}}],"resources":[{"name":"ActivatedImage","resourceType":"ResourceTypes::Image::PNG","value":{"resourceValueType":"ResourceValueType::URI","value":"https://cdn.blockv.io/templates/vatomic.prototyping/HeinekenProgress/v1/HeinekenProgressVatom/v2/ActivatedImage.png"}},{"name":"BaseImage","resourceType":"ResourceTypes::Image::PNG","value":{"resourceValueType":"ResourceValueType::URI","value":"https://cdn.blockv.io/templates/vatomic.prototyping/HeinekenProgress/v1/HeinekenProgressVatom/v2/BaseImage.png"}},{"name":"ZeroShareCard","resourceType":"ResourceTypes::Image::PNG","value":{"resourceValueType":"ResourceValueType::URI","value":"https://cdn.blockv.io/templates/vatomic.prototyping/HeinekenProgress/v1/HeinekenProgressVatom/v2/ZeroShareCard.png"}},{"name":"OneShareCard","resourceType":"ResourceTypes::Image::PNG","value":{"resourceValueType":"ResourceValueType::URI","value":"https://cdn.blockv.io/templates/vatomic.prototyping/HeinekenProgress/v1/HeinekenProgressVatom/v2/OneShareCard.png"}}],"visibility":{"type":"owner","value":"*"},"num_direct_clones":2,"geo_pos":{"$reql_type$":"GEOMETRY","coordinates":[0,0],"type":"Point"},"location":{"uri":""},"dropped":true},"private":{"array":[1,2,3],"boolean":true,"color":"#82b92c","null":null,"number":123,"object":{"a":"b","c":"d","e":{"foo":"bar"}},"string":"Hello World"},"eos":{"symbol":"","network":"testnet","fields":{"lighton":{"type":"bool","value":false}}},"unpublished":false,"version":"v1::vAtomType","sync":0}
            """.data(using: .utf8)!

    }

    public enum PackModel {

        public static let Example1 = """
            {"request_id":"04fa82c4-2c5f-463a-aff1-2ffed6fad123","payload":{"vatoms":[{"id":"4389ec35-9fc4-4f31-1232-8cb6bcaa8b19","when_created":"2018-07-24T12:04:52Z","when_modified":"2018-07-24T13:34:07Z","vAtom::vAtomType":{"parent_id":".","publisher_fqdn":"vatomic.prototyping","root_type":"vAtom::vAtomType","owner":"21c527fb-8a8b-485b-b549-61b3857e5807","author":"2e1038f8-ffcd-4e91-aa81-ccfc74ae9d79","template":"vatomic.prototyping::tutorial::3D-Object::v1","template_variation":"vatomic.prototyping::tutorial::3D-Object::v1::Butterfly::v1","notify_msg":"","title":"Monarch Butterfly","description":"Developer Tutorial 3D Object vAtom.","disabled":false,"category":"Education","tags":[],"transferable":false,"acquirable":false,"tradeable":false,"transferred_by":"","cloned_from":"","cloning_score":0,"in_contract":false,"redeemable":false,"in_contract_with":"","commerce":{"pricing":{"pricingType":"","value":{"currency":"","price":"","valid_from":"","valid_through":"","vat_included":false}}},"states":[{"name":"Activated","value":{"type":"boolean","value":"true"},"on_state_change":{"reactor":""}}],"resources":[{"name":"ActivatedImage","resourceType":"ResourceType::Image::PNG","value":{"resourceValueType":"ResourceValueType::URI","value":"https://cdn.blockv.io/vatomic.prototyping/vatomic.prototyping::v1::3D-Object/butterfly_icon.png"}},{"name":"CardImage","resourceType":"ResourceType::Image::JPEG","value":{"resourceValueType":"ResourceValueType::URI","value":"https://cdn.blockv.io/vatomic.prototyping/vatomic.prototyping::v1::3D-Object/butterfly_card.jpg"}},{"name":"Scene","resourceType":"ResourceType::3D::Scene","value":{"resourceValueType":"ResourceValueType::URI","value":"https://cdn.blockv.io/vatomic.prototyping/vatomic.prototyping::v1::3D-Object/butterfly.v3d"}}],"visibility":{"type":"owner","value":"*"},"num_direct_clones":0,"geo_pos":{"$reql_type$":"GEOMETRY","coordinates":[0,0],"type":"Point"},"dropped":false},"private":{"allows_user_rotation":true,"allows_user_zoom":true,"auto_rotate_x":0,"auto_rotate_y":0,"auto_rotate_z":0,"play_animation":true,"resources":[],"scene_resource_name":""},"unpublished":true,"version":"v1::vAtomType"},{"id":"d24b9556-59e9-446d-123b-4c7378e06b99","when_created":"2018-06-08T08:42:52Z","when_modified":"2018-06-08T08:42:52Z","vAtom::vAtomType":{"parent_id":".","publisher_fqdn":"vatomic.prototyping","root_type":"vAtom::vAtomType","owner":"21c527fb-8a8b-485b-b549-61b3857e5807","author":"2e1038f8-ffcd-4e91-aa81-ccfc74ae9d79","template":"vatomic.prototyping::3D-Object::v1","template_variation":"vatomic.prototyping::3D-Object::v1::SecretKey::v1","notify_msg":"","title":"Secret Key","description":"This is a secret key! You can unlock a crate to win a prize","disabled":false,"category":"Gifts","tags":[],"transferable":true,"acquirable":true,"tradeable":false,"transferred_by":"2e1038f8-ffcd-4e91-aa81-ccfc74ae9d79","cloned_from":"","cloning_score":0,"in_contract":false,"redeemable":false,"in_contract_with":"","commerce":{"pricing":{"pricingType":"Fixed","value":{"currency":"","price":"","valid_from":"*","valid_through":"*","vat_included":false}}},"states":[{"name":"Activated","value":{"type":"boolean","value":"true"},"on_state_change":{"reactor":""}}],"resources":[{"name":"ActivatedImage","resourceType":"ResourceTypes::Image::PNG","value":{"resourceValueType":"ResourceValueType::URI","value":"https://cdn.blockv.io/templates/vatomic.prototyping%3A%3A3D-Object%3A%3Av1%3A%3ASecretKey%3A%3Av1/1266782c-526d-4519-a74b-3d08694dae7b.png"}},{"name":"CardImage","resourceType":"ResourceTypes::Image::PNG","value":{"resourceValueType":"ResourceValueType::URI","value":"https://cdn.blockv.io/templates/vatomic.prototyping%3A%3A3D-Object%3A%3Av1%3A%3ASecretKey%3A%3Av1/69b263e1-52be-4079-ae55-8eac59d574c3.jpg"}},{"name":"Scene","resourceType":"ResourceTypes::3D::Scene","value":{"resourceValueType":"ResourceValueType::URI","value":"https://cdn.blockv.io/templates/vatomic.prototyping%3A%3A3D-Object%3A%3Av1%3A%3ASecretKey%3A%3Av1/d13cb66d-ba2d-4a90-ab72-f2ffe92a69a0.v3d"}}],"visibility":{"type":"owner","value":"*"},"num_direct_clones":0,"geo_pos":{"$reql_type$":"GEOMETRY","coordinates":[0,0],"type":"Point"},"dropped":false},"private":{"allows_user_rotation":true,"allows_user_zoom":true,"auto_rotate_x":0,"auto_rotate_y":0,"auto_rotate_z":0,"play_animation":true},"unpublished":false,"version":"v1::vAtomType"},{"id":"009b12ac-bd27-4bb4-a123-73faa2f0e270","when_created":"2018-01-16T10:47:33Z","when_modified":"2018-06-06T14:08:45Z","vAtom::vAtomType":{"parent_id":".","publisher_fqdn":"vatomic.prototyping","root_type":"vAtom::vAtomType","owner":"21c527fb-8a8b-485b-b549-61b3857e5807","author":"715e0e66-3b18-4719-a927-3e06221ef95b","template":"vatomic.prototyping::ProgressRedeem::v1","template_variation":"vatomic.prototyping::ProgressRedeem::v1::CokeDemo::v1","notify_msg":"","title":"Coke Demo","description":"A vAtom to demo sharing and redeem","disabled":false,"category":"Food & Drink","tags":[],"transferable":true,"acquirable":false,"tradeable":false,"transferred_by":"87ea4219-d708-4c94-88eb-afc48e392147","cloned_from":"","cloning_score":0.25,"in_contract":false,"redeemable":true,"in_contract_with":"","commerce":{"pricing":{"pricingType":"Fixed","value":{"currency":"","price":"","valid_from":"*","valid_through":"*","vat_included":false}}},"states":[{"name":"Activated","value":{"type":"boolean","value":"true"},"on_state_change":{"reactor":""}}],"resources":[{"name":"ActivatedImage","resourceType":"ResourceTypes::Image::PNG","value":{"resourceValueType":"ResourceValueType::URI","value":"https://cdn.blockv.io/templates/vatomic.prototyping/ProgressRedeem/v1/CokeDemo/v1/e69574ea-5ff9-425a-8421-44d2490576d1.png"}},{"name":"BaseImage","resourceType":"ResourceTypes::Image::PNG","value":{"resourceValueType":"ResourceValueType::URI","value":"https://cdn.blockv.io/templates/vatomic.prototyping/ProgressRedeem/v1/CokeDemo/v1/7887de52-923e-4fc8-a0fb-bb6e397e51c4.png"}},{"name":"CardBackground","resourceType":"ResourceTypes::Image::PNG","value":{"resourceValueType":"ResourceValueType::URI","value":"https://cdn.blockv.io/templates/vatomic.prototyping/ProgressRedeem/v1/CokeDemo/v1/9b60707e-5ef9-499d-90fe-167cc579db5a.jpg"}},{"name":"ActivatedImage","resourceType":"ResourceTypes::Image::PNG","value":{"resourceValueType":"ResourceValueType::URI","value":"https://cdn.blockv.io/templates/vatomic.prototyping/ProgressRedeem/v1/CokeDemo/v1/e69574ea-5ff9-425a-8421-44d2490576d1.png"}},{"name":"BaseImage","resourceType":"ResourceTypes::Image::PNG","value":{"resourceValueType":"ResourceValueType::URI","value":"https://cdn.blockv.io/templates/vatomic.prototyping/ProgressRedeem/v1/CokeDemo/v1/7887de52-923e-4fc8-a0fb-bb6e397e51c4.png"}},{"name":"CardBackground","resourceType":"ResourceTypes::Image::PNG","value":{"resourceValueType":"ResourceValueType::URI","value":"https://cdn.blockv.io/templates/vatomic.prototyping/ProgressRedeem/v1/CokeDemo/v1/9b60707e-5ef9-499d-90fe-167cc579db5a.jpg"}}],"visibility":{"type":"owner","value":"*"},"num_direct_clones":1,"geo_pos":{"$reql_type$":"GEOMETRY","coordinates":[0,0],"type":"Point"},"dropped":false},"private":{"direction":"up","merchant_id":"","padding_end":83,"padding_start":3,"qr_css":"position: absolute; z-index: 1; bottom: 6vw; right: 6vw; width: 100%; height: 24vw; background-position: right; background-size: contain; background-repeat: no-repeat;","qr_data":"redeem://{{vatom.id}}","redeem_action":"Redeem","redeem_button_background_color":"#DF3235","redeem_button_text_color":"#FFFFFF","redeem_merchant_filter":"CokeMerchant","redeem_text":"Redeem","required_cloning_score":1,"required_cloning_score_css":"position: absolute; bottom: 110px; left: 20px; width: calc(100% - 40px); text-align: center; font-family: Helvetica, Arial; font-size: 15px; color: #DDD;","required_cloning_score_text":"Please share this vAtom more","show_percentage":true},"unpublished":false,"version":"v1::vAtomType"}],"faces":[{"id":"30afe04a-7a23-4ab9-9652-22fcbd687123","template":"vatomic.prototyping::tutorial::3D-Object::v1","meta":{"created_by":"BLOCKv Backend","when_created":"2018-07-24T12:14:18Z","modified_by":"","when_modified":"2018-07-24T12:14:18Z","data_type":"v1::FaceType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"display_url":"native://generic-3d","package_url":"native://generic-3d","constraints":{"bluetooth_le":false,"contact_list":false,"gps":false,"three_d":true,"view_mode":"icon","platform":"generic","quality":"high"},"resources":["Scene"]}},{"id":"722a50ba-3a5a-4187-8ecb-123a38e0944a","template":"vatomic.prototyping::tutorial::3D-Object::v1","meta":{"created_by":"BLOCKv Backend","when_created":"2018-07-24T12:22:49Z","modified_by":"","when_modified":"2018-07-24T12:22:49Z","data_type":"v1::FaceType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"display_url":"native://image","package_url":"native://image","constraints":{"bluetooth_le":false,"contact_list":false,"gps":false,"three_d":false,"view_mode":"card","platform":"generic","quality":"high"},"resources":["CardImage"]}},{"id":"3240ef61-0766-416c-1235-26cb4a6803f0","template":"vatomic.prototyping::3D-Object::v1","meta":{"created_by":"Appdriver Backend","when_created":"2017-10-24T17:42:41Z","modified_by":"","when_modified":"2017-10-24T17:42:41Z","data_type":"v1::FaceType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"display_url":"native://image","package_url":"native://image","constraints":{"bluetooth_le":false,"contact_list":false,"gps":false,"three_d":false,"view_mode":"icon","platform":"android","quality":"high"},"resources":["ActivatedImage"]}},{"id":"5b042b7d-d5e1-4123-8093-81f8bd4c02c2","template":"vatomic.prototyping::3D-Object::v1","meta":{"created_by":"Appdriver Backend","when_created":"2017-05-26T19:22:13Z","modified_by":"","when_modified":"2017-05-26T19:22:13Z","data_type":"v1::FaceType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"display_url":"native://generic-3d","package_url":"native://generic-3d","constraints":{"bluetooth_le":false,"contact_list":false,"gps":false,"three_d":true,"view_mode":"icon","platform":"web","quality":"high"},"resources":["Scene"]}},{"id":"7c6aa256-fa02-4335-a123-04e1a1874f6d","template":"vatomic.prototyping::3D-Object::v1","meta":{"created_by":"Appdriver Backend","when_created":"2017-11-20T16:18:39Z","modified_by":"","when_modified":"2017-11-20T16:18:39Z","data_type":"v1::FaceType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"display_url":"native://generic-3d","package_url":"native://generic-3d","constraints":{"bluetooth_le":false,"contact_list":false,"gps":false,"three_d":true,"view_mode":"icon","platform":"android","quality":"high"},"resources":["Scene"]}},{"id":"9509279d-09ca-4123-a761-3298af97964f","template":"vatomic.prototyping::3D-Object::v1","meta":{"created_by":"Appdriver Backend","when_created":"2017-05-26T19:21:58Z","modified_by":"","when_modified":"2017-05-26T19:21:58Z","data_type":"v1::FaceType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"display_url":"native://generic-3d","package_url":"native://generic-3d","constraints":{"bluetooth_le":false,"contact_list":false,"gps":false,"three_d":true,"view_mode":"icon","platform":"ios","quality":"high"},"resources":["Scene"]}},{"id":"b36ece9e-e5af-4123-ae14-5615364303c3","template":"vatomic.prototyping::3D-Object::v1","meta":{"created_by":"Appdriver Backend","when_created":"2017-05-26T19:21:28Z","modified_by":"","when_modified":"2017-05-26T19:21:28Z","data_type":"v1::FaceType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"display_url":"native://image","package_url":"native://image","constraints":{"bluetooth_le":false,"contact_list":false,"gps":false,"three_d":false,"view_mode":"card","platform":"web","quality":"high"},"resources":["CardImage"]}},{"id":"48a0d8e8-9d77-44ba-aee4-941239771061","template":"vatomic.prototyping::3D-Object::v1","meta":{"created_by":"Appdriver Backend","when_created":"2017-05-26T19:21:33Z","modified_by":"","when_modified":"2017-05-26T19:21:33Z","data_type":"v1::FaceType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"display_url":"native://image","package_url":"native://image","constraints":{"bluetooth_le":false,"contact_list":false,"gps":false,"three_d":false,"view_mode":"card","platform":"ios","quality":"high"},"resources":["CardImage"]}},{"id":"52860345-c2b6-4235-a76c-a0b1237f7d39","template":"vatomic.prototyping::ProgressRedeem::v1","meta":{"created_by":"Appdriver Backend","when_created":"2018-01-16T10:04:48Z","modified_by":"","when_modified":"2018-01-16T10:04:48Z","data_type":"v1::FaceType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"display_url":"https://viewer.vatomic.io/faces/redeem-card/index.html","package_url":"https://viewer.vatomic.io/faces/redeem-card/index.html","constraints":{"bluetooth_le":false,"contact_list":false,"gps":false,"three_d":false,"view_mode":"fullscreen","platform":"web","quality":"high"},"resources":["CardBackground"]}},{"id":"75d95f3f-b8b2-4ec1-9029-d226123d15dc","template":"vatomic.prototyping::ProgressRedeem::v1","meta":{"created_by":"Appdriver Backend","when_created":"2018-01-16T10:04:48Z","modified_by":"","when_modified":"2018-01-16T10:04:48Z","data_type":"v1::FaceType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"display_url":"native://progress-image-overlay","package_url":"native://progress-image-overlay","constraints":{"bluetooth_le":false,"contact_list":false,"gps":false,"three_d":false,"view_mode":"icon","platform":"android","quality":"high"},"resources":["ActivatedImage","BaseImage"]}},{"id":"b32ea802-9818-433b-8ed0-3123e1ce5a71","template":"vatomic.prototyping::ProgressRedeem::v1","meta":{"created_by":"Appdriver Backend","when_created":"2018-01-16T10:04:48Z","modified_by":"","when_modified":"2018-01-16T10:04:48Z","data_type":"v1::FaceType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"display_url":"https://viewer.vatomic.io/faces/redeem-card/index.html","package_url":"https://viewer.vatomic.io/faces/redeem-card/index.html","constraints":{"bluetooth_le":false,"contact_list":false,"gps":false,"three_d":false,"view_mode":"fullscreen","platform":"ios","quality":"high"},"resources":["CardBackground"]}},{"id":"bae3c936-9034-489c-b123-bc144d96e2eb","template":"vatomic.prototyping::ProgressRedeem::v1","meta":{"created_by":"Appdriver Backend","when_created":"2018-01-16T10:04:48Z","modified_by":"","when_modified":"2018-01-16T10:04:48Z","data_type":"v1::FaceType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"display_url":"native://progress-image-overlay","package_url":"native://progress-image-overlay","constraints":{"bluetooth_le":false,"contact_list":false,"gps":false,"three_d":false,"view_mode":"icon","platform":"ios","quality":"high"},"resources":["ActivatedImage","BaseImage"]}},{"id":"d60e273b-a197-123f-8c9a-78ddc3776a34","template":"vatomic.prototyping::ProgressRedeem::v1","meta":{"created_by":"Appdriver Backend","when_created":"2018-01-16T10:04:48Z","modified_by":"","when_modified":"2018-01-16T10:04:48Z","data_type":"v1::FaceType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"display_url":"https://viewer.vatomic.io/faces/redeem-card/index.html","package_url":"https://viewer.vatomic.io/faces/redeem-card/index.html","constraints":{"bluetooth_le":false,"contact_list":false,"gps":false,"three_d":false,"view_mode":"fullscreen","platform":"android","quality":"high"},"resources":["CardBackground"]}},{"id":"c386e123-b4fd-4f04-a641-7b72d6dc5cf7","template":"vatomic.prototyping::ProgressRedeem::v1","meta":{"created_by":"Appdriver Backend","when_created":"2018-01-16T10:04:48Z","modified_by":"","when_modified":"2018-01-16T10:04:48Z","data_type":"v1::FaceType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"display_url":"native://progress-image-overlay","package_url":"native://progress-image-overlay","constraints":{"bluetooth_le":false,"contact_list":false,"gps":false,"three_d":false,"view_mode":"icon","platform":"web","quality":"high"},"resources":["ActivatedImage","BaseImage"]}}],"actions":[{"name":"vatomic.prototyping::tutorial::3D-Object::v1::Action::AcquirePubVariation","meta":{"created_by":"BLOCKv Backend","when_created":"2018-07-24T12:02:15Z","modified_by":"","when_modified":"2018-07-24T12:02:15Z","data_type":"v1::ActionType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"name":"vatomic.prototyping::tutorial::3D-Object::v1::Action::AcquirePubVariation","reactor":"blockv://v1/AcquirePubVariationWithCoins","wait":true,"rollback":false,"abort_on_pre_error":true,"abort_on_post_error":false,"abort_on_main_error":true,"timeout":10000,"guest_user":true,"state_impact":["this.owner"],"policy":{"pre":[],"rule":"","post":[]},"params":{"input":["this.id"],"output":["vAtomic::v1::Error"]},"config":{"auto_create_landing_page":"https://land.blockv.io/#","auto_create_mode":"claim","auto_create_non_existing_recipient":true},"limit_per_user":0,"action_notification":{"on":false,"msg":"","custom":{}}}},{"name":"vatomic.prototyping::3D-Object::v1::Action::Pickup","meta":{"created_by":"Blockv Backend","when_created":"2017-05-26T19:24:47Z","modified_by":"","when_modified":"2017-05-26T19:24:47Z","data_type":"v1::ActionType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"name":"vatomic.prototyping::3D-Object::v1::Action::Pickup","reactor":"blockv://v1/Pickup","wait":true,"rollback":false,"abort_on_pre_error":true,"abort_on_post_error":false,"abort_on_main_error":true,"timeout":10000,"guest_user":true,"state_impact":["this.owner"],"policy":{"pre":[],"rule":"","post":[]},"params":{"input":["this.id"],"output":["vAtomic::v1::Error"]},"config":{},"limit_per_user":0,"action_notification":{"on":false,"msg":"","custom":{}}}},{"name":"vatomic.prototyping::3D-Object::v1::Action::Drop","meta":{"created_by":"Blockv Backend","when_created":"2017-05-26T19:24:37Z","modified_by":"","when_modified":"2017-05-26T19:24:37Z","data_type":"v1::ActionType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"name":"vatomic.prototyping::3D-Object::v1::Action::Drop","reactor":"blockv://v1/Drop","wait":true,"rollback":false,"abort_on_pre_error":true,"abort_on_post_error":false,"abort_on_main_error":true,"timeout":10000,"guest_user":true,"state_impact":["this.owner"],"policy":{"pre":[],"rule":"","post":[]},"params":{"input":["this.id","geo.pos"],"output":["vAtomic::v1::Error"]},"config":{},"limit_per_user":0,"action_notification":{"on":false,"msg":"","custom":{}}}},{"name":"vatomic.prototyping::3D-Object::v1::Action::Acquire","meta":{"created_by":"Blockv Backend","when_created":"2017-11-15T18:37:45Z","modified_by":"","when_modified":"2017-11-15T18:37:45Z","data_type":"v1::ActionType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"name":"vatomic.prototyping::3D-Object::v1::Action::Acquire","reactor":"blockv://v1/AcquireWithCoins","wait":true,"rollback":false,"abort_on_pre_error":true,"abort_on_post_error":false,"abort_on_main_error":true,"timeout":10000,"guest_user":true,"state_impact":["this.owner"],"policy":{"pre":[],"rule":"","post":[]},"params":{"input":["this.id"],"output":["vAtomic::v1::Error"]},"config":{"auto_create_landing_page":"https://land.blockv.io/#","auto_create_mode":"claim","auto_create_non_existing_recipient":true},"limit_per_user":0,"action_notification":{"on":false,"msg":"","custom":null}}},{"name":"vatomic.prototyping::3D-Object::v1::Action::Transfer","meta":{"created_by":"Blockv Backend","when_created":"2018-03-07T18:37:19Z","modified_by":"","when_modified":"2018-03-07T18:37:19Z","data_type":"v1::ActionType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"name":"vatomic.prototyping::3D-Object::v1::Action::Transfer","reactor":"blockv://v1/Transfer","wait":true,"rollback":false,"abort_on_pre_error":true,"abort_on_post_error":false,"abort_on_main_error":true,"timeout":10000,"guest_user":true,"state_impact":["this.owner"],"policy":{"pre":[],"rule":"","post":[]},"params":{"input":["this.id","new.owner.email|new.owner.phone_number|new.owner.id"],"output":["vAtomic::v1::Error"]},"config":{"auto_create_landing_page":"https://land.blockv.io/#","auto_create_mode":"claim","auto_create_non_existing_recipient":true},"limit_per_user":0,"action_notification":{"on":true,"msg":"You received a vAtom","custom":{}}}},{"name":"vatomic.prototyping::3D-Object::v1::Action::AcquirePubVariation","meta":{"created_by":"BLOCKv Backend","when_created":"2018-07-17T00:15:55Z","modified_by":"","when_modified":"2018-07-17T00:15:55Z","data_type":"v1::ActionType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"name":"vatomic.prototyping::3D-Object::v1::Action::AcquirePubVariation","reactor":"blockv://v1/AcquirePubVariationWithCoins","wait":true,"rollback":false,"abort_on_pre_error":true,"abort_on_post_error":false,"abort_on_main_error":true,"timeout":10000,"guest_user":true,"state_impact":[],"policy":{"pre":[],"rule":"","post":[]},"params":{"input":["this.id"],"output":["vAtomic::v1::Error"]},"config":{"auto_create_landing_page":"https://land.blockv.io/#","auto_create_mode":"claim","auto_create_non_existing_recipient":true},"limit_per_user":0,"action_notification":{"on":true,"msg":"You received a vAtom","custom":{}}}},{"name":"vatomic.prototyping::3D-Object::v1::Action::Trade","meta":{"created_by":"Blockv Backend","when_created":"2017-05-26T19:23:57Z","modified_by":"","when_modified":"2017-05-26T19:23:57Z","data_type":"v1::ActionType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"name":"vatomic.prototyping::3D-Object::v1::Action::Trade","reactor":"blockv://v1/Trade","wait":true,"rollback":false,"abort_on_pre_error":true,"abort_on_post_error":false,"abort_on_main_error":true,"timeout":10000,"guest_user":true,"state_impact":["this.owner"],"policy":{"pre":[],"rule":"","post":[]},"params":{"input":["this.id","trade.template_variation","trade.conditions"],"output":["vAtomic::v1::Error"]},"config":{},"limit_per_user":0,"action_notification":{"on":false,"msg":"","custom":null}}},{"name":"vatomic.prototyping::ProgressRedeem::v1::Action::AcquirePubVariation","meta":{"created_by":"Blockv Backend","when_created":"2018-02-23T13:09:01Z","modified_by":"","when_modified":"2018-02-23T13:09:01Z","data_type":"v1::ActionType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"name":"vatomic.prototyping::ProgressRedeem::v1::Action::AcquirePubVariation","reactor":"blockv://v1/AcquirePubVariationWithCoins","wait":true,"rollback":false,"abort_on_pre_error":true,"abort_on_post_error":false,"abort_on_main_error":true,"timeout":10000,"guest_user":true,"state_impact":["this.owner"],"policy":{"pre":[],"rule":"","post":[]},"params":{"input":["this.id"],"output":["vAtomic::v1::Error"]},"config":{"auto_create_landing_page":"http://viewer.vatomic.io/land/#","auto_create_mode":"claim","auto_create_non_existing_recipient":true},"limit_per_user":0,"action_notification":{"on":false,"msg":"","custom":{}}}},{"name":"vatomic.prototyping::ProgressRedeem::v1::Action::Acquire","meta":{"created_by":"Blockv Backend","when_created":"2018-01-16T10:04:47Z","modified_by":"","when_modified":"2018-01-16T10:04:47Z","data_type":"v1::ActionType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"name":"vatomic.prototyping::ProgressRedeem::v1::Action::Acquire","reactor":"blockv://v1/AcquireWithCoins","wait":true,"rollback":false,"abort_on_pre_error":true,"abort_on_post_error":false,"abort_on_main_error":true,"timeout":10000,"guest_user":true,"state_impact":["this.owner"],"policy":{"pre":[],"rule":"","post":[]},"params":{"input":["this.id"],"output":["vAtomic::v1::Error"]},"config":{},"limit_per_user":0,"action_notification":{"on":false,"msg":"","custom":null}}},{"name":"vatomic.prototyping::ProgressRedeem::v1::Action::Redeem","meta":{"created_by":"Blockv Backend","when_created":"2018-01-16T10:04:47Z","modified_by":"","when_modified":"2018-01-16T10:04:47Z","data_type":"v1::ActionType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"name":"vatomic.prototyping::ProgressRedeem::v1::Action::Redeem","reactor":"blockv://v1/Redeem","wait":true,"rollback":false,"abort_on_pre_error":true,"abort_on_post_error":false,"abort_on_main_error":true,"timeout":10000,"guest_user":true,"state_impact":["this.owner"],"policy":{"pre":[],"rule":"","post":[]},"params":{"input":["this.id"],"output":["vAtomic::v1::Error"]},"config":{},"limit_per_user":0,"action_notification":{"on":false,"msg":"a vAtom has been redeemed","custom":{}}}},{"name":"vatomic.prototyping::ProgressRedeem::v1::Action::Trade","meta":{"created_by":"Blockv Backend","when_created":"2018-01-16T10:04:47Z","modified_by":"","when_modified":"2018-01-16T10:04:47Z","data_type":"v1::ActionType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"name":"vatomic.prototyping::ProgressRedeem::v1::Action::Trade","reactor":"blockv://v1/Trade","wait":true,"rollback":false,"abort_on_pre_error":true,"abort_on_post_error":false,"abort_on_main_error":true,"timeout":10000,"guest_user":true,"state_impact":["this.owner"],"policy":{"pre":[],"rule":"","post":[]},"params":{"input":["this.id","trade.template_variation","trade.conditions"],"output":["vAtomic::v1::Error"]},"config":{},"limit_per_user":0,"action_notification":{"on":false,"msg":"","custom":null}}},{"name":"vatomic.prototyping::ProgressRedeem::v1::Action::Drop","meta":{"created_by":"Blockv Backend","when_created":"2018-01-16T10:04:47Z","modified_by":"","when_modified":"2018-01-16T10:04:47Z","data_type":"v1::ActionType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"name":"vatomic.prototyping::ProgressRedeem::v1::Action::Drop","reactor":"blockv://v1/Drop","wait":true,"rollback":false,"abort_on_pre_error":true,"abort_on_post_error":false,"abort_on_main_error":true,"timeout":10000,"guest_user":true,"state_impact":["this.owner"],"policy":{"pre":[],"rule":"","post":[]},"params":{"input":["this.id","geo.pos"],"output":["vAtomic::v1::Error"]},"config":{},"limit_per_user":0,"action_notification":{"on":false,"msg":"","custom":{}}}},{"name":"vatomic.prototyping::ProgressRedeem::v1::Action::Clone","meta":{"created_by":"Blockv Backend","when_created":"2018-02-23T13:08:06Z","modified_by":"","when_modified":"2018-02-23T13:08:06Z","data_type":"v1::ActionType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"name":"vatomic.prototyping::ProgressRedeem::v1::Action::Clone","reactor":"blockv://v1/Clone","wait":true,"rollback":false,"abort_on_pre_error":true,"abort_on_post_error":false,"abort_on_main_error":true,"timeout":10000,"guest_user":true,"state_impact":["this.owner"],"policy":{"pre":[],"rule":"","post":[]},"params":{"input":["this.id"],"output":["vAtomic::v1::Error"]},"config":{"auto_create_landing_page":"https://land.blockv.io/#","auto_create_mode":"claim","auto_create_non_existing_recipient":true},"limit_per_user":0,"action_notification":{"on":false,"msg":"","custom":{}}}},{"name":"vatomic.prototyping::ProgressRedeem::v1::Action::Pickup","meta":{"created_by":"Blockv Backend","when_created":"2018-01-16T10:04:47Z","modified_by":"","when_modified":"2018-01-16T10:04:47Z","data_type":"v1::ActionType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"name":"vatomic.prototyping::ProgressRedeem::v1::Action::Pickup","reactor":"blockv://v1/Pickup","wait":true,"rollback":false,"abort_on_pre_error":true,"abort_on_post_error":false,"abort_on_main_error":true,"timeout":10000,"guest_user":true,"state_impact":["this.owner"],"policy":{"pre":[],"rule":"","post":[]},"params":{"input":["this.id"],"output":["vAtomic::v1::Error"]},"config":{},"limit_per_user":0,"action_notification":{"on":false,"msg":"","custom":{}}}},{"name":"vatomic.prototyping::ProgressRedeem::v1::Action::Transfer","meta":{"created_by":"Blockv Backend","when_created":"2018-02-23T13:09:42Z","modified_by":"","when_modified":"2018-02-23T13:09:42Z","data_type":"v1::ActionType","in_sync":false,"when_synced":"","is_syncing":false},"properties":{"name":"vatomic.prototyping::ProgressRedeem::v1::Action::Transfer","reactor":"blockv://v1/Transfer","wait":true,"rollback":false,"abort_on_pre_error":true,"abort_on_post_error":false,"abort_on_main_error":true,"timeout":10000,"guest_user":true,"state_impact":["this.owner"],"policy":{"pre":[],"rule":"","post":[]},"params":{"input":["this.id","new.owner.email|new.owner.phone_number|new.owner.id"],"output":["vAtomic::v1::Error"]},"config":{"auto_create_landing_page":"https://land.blockv.io/#","auto_create_mode":"claim","auto_create_non_existing_recipient":true},"limit_per_user":0,"action_notification":{"on":true,"msg":"You received a vAtom","custom":{}}}}]}}
            """.data(using: .utf8)!
    }
}
