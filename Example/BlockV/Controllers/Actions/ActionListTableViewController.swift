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
    
    // For now, we hardcode to display a single action.
    //
    // In a future release, the actions configure for the vAtom's template
    // will be returned.
    fileprivate var actions: [String] = ["Transfer"]
    
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
        
        let templateID = self.vatom.props.templateID
        
        BLOCKv.getActions(forTemplateID: templateID) { (actions, error) in
            
            // unwrap actions, handle error
            guard let actions = actions, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            // success
            print("Actions: \(actions.debugDescription)")
            
        }
        
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
