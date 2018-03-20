//
//  ActionListTableViewController.swift
//  BlockV_Example
//

import UIKit
import BlockV

/// This class lists the available actions for the passed in vAtom.
///
/// The view controller will list all actions configured on the vAtom's
/// template.
class ActionListTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    var vatom: Vatom!
    
    // For now, we hardcode to display a single action.
    //
    // In a future release, the actions configure for the vAtom's template
    // will be returned.
    var actions: [String] = ["Transfer"]
    
    // MARK: - Actions
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        precondition(vatom != nil, "A vAtom must be passed into this view controller.")
        
    }


    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as! TransferActionViewController
        destination.vatom = self.vatom
    }

}

// MARK: - Table view data source

extension ActionListTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell.action.id", for: indexPath)
        cell.textLabel?.text = actions[indexPath.row]
        return cell
    }
    
}
