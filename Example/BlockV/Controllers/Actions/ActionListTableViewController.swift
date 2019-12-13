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

    /// Currently selected action.
    var selectedAction: AvailableAction?

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

        BLOCKv.getActions(forTemplateID: templateID) { result in

            self.hideNavBarActivityRight()

            switch result {
            case .success(let actions):
                // success
                print("Actions: \(actions.debugDescription)")
                // update data source
                self.availableActions = actions.map { action -> AvailableAction in
                    // record
                    let supported = self.supportedActions.contains(action.name)
                    return AvailableAction(action: action, isSupported: supported)
                }
                self.tableView.reloadData()

            case .failure(let error):
                print(error.localizedDescription)
            }

        }

    }

    /// Prompts the user to optionally delete the vatom.
    fileprivate func deleteVatom() {

        let message = "This vAtom will be deleted from all your devices."
        let alert = UIAlertController.confirmAlert(title: "Delete vAtom", message: message) { confirmed in
            if confirmed {
                BLOCKv.trashVatom(self.vatom.id) { [weak self] _ in
                    self?.hide()
                }
            }
        }

        self.present(alert, animated: true, completion: nil)

    }

    fileprivate func hide() {
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
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

}

// MARK: - Table view data source

extension ActionListTableViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return availableActions.count
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell.action.id", for: indexPath)
            let availableAction = availableActions[indexPath.row]
            cell.textLabel?.text = availableAction.action.name
            cell.textLabel?.alpha = availableAction.isSupported ? 1 : 0.5
            cell.accessoryView = nil
            return cell
        }

        let cell = UITableViewCell.init(style: .default, reuseIdentifier: "id.cell.delete")
        cell.textLabel?.textColor = UIColor.destruciveOrange
        cell.textLabel?.text = "Delete"
        return cell

    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if indexPath.section == 0 {
            selectedAction = availableActions[indexPath.row]
            if selectedAction!.isSupported {
                self.performSegue(withIdentifier: "seg.action.selection", sender: self)
            }
        } else {
            self.deleteVatom()
        }
    }

}
