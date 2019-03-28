//  MIT License
//
//  Copyright (c) 2018 BlockV AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

//
//  ActionListTableViewController.swift
//  BlockV_Example
//

import UIKit
import BLOCKv

/// This class lists the available actions for the passed in vAtom.
///
/// The view controller will list all actions configured on the vAtom's
/// template.
class ActionListTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    var vatom: VatomModel!
    
    // table view data model
    struct AvailableAction {
        let action: ActionModel
        /// Flag indicating whether this action is supported by this viewer.
        let isSupported: Bool
    }
    
    /// List of available actions.
    fileprivate var availableActions: [AvailableAction] = []
    
    /// List of actions this viewer supports (i.e. knows how to handle).
    private var supportedActions = ["Transfer", "Clone", "Redeem"]
    
    // MARK: - Actions
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        precondition(vatom != nil, "A vAtom must be passed into this view controller.")
        
        fetchActions()
    }

    // MARK: - Helpers
    
    /// Fetches all the actions configured / associated with our vAtom's template.
    fileprivate func fetchActions() {
        
        self.showNavBarActivityRight()
        
        let templateID = self.vatom.props.templateID
        
        BLOCKv.getActions(forTemplateID: templateID) { (actions, error) in
            
            self.hideNavBarActivityRight()
            
            // unwrap actions, handle error
            guard let actions = actions, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            // success
            print("Actions: \(actions.debugDescription)")
            // update data source
            self.availableActions = actions.map { action -> AvailableAction in
                // record
                let supported = self.supportedActions.contains(action.name)
                return AvailableAction(action: action, isSupported: supported)
            }
            self.tableView.reloadData()
            
        }
        
    }

    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return false
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // dependecy injection
        let destination = segue.destination as! OutboundActionViewController
        destination.vatom = self.vatom
        destination.actionName = self.selectedAction!.action.name
    }
    
    var selectedAction: AvailableAction?
    
}

// MARK: - Table view data source

extension ActionListTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableActions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell.action.id", for: indexPath)
        let availableAction = availableActions[indexPath.row]
        cell.textLabel?.text = availableAction.action.name
        cell.textLabel?.alpha = availableAction.isSupported ? 1 : 0.5
        cell.accessoryView = nil
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedAction = availableActions[indexPath.row]
        if selectedAction!.isSupported {
            self.performSegue(withIdentifier: "seg.action.selection", sender: self)
        }
    }
    
}
