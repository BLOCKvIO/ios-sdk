//
//  ItemValueCell.swift
//  BlockV_Example
//
//  Created by Cameron McOnie on 2018/03/10.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

/// This cell is used for data capture.
class TitleValueCell: UITableViewCell {
    
    // MARK: - Outlets
    
    /// Title label
    var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// Value text field (for editing)
    var valueTextField: UITextField = {
        let textfield = UITextField()
        textfield.translatesAutoresizingMaskIntoConstraints = false
        return textfield
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(valueTextField)
        
        titleLabel.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: valueTextField.leadingAnchor, constant: -5)
        
        valueTextField.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        valueTextField.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor, constant: 126).isActive = true
        valueTextField.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor).isActive = true
        valueTextField.heightAnchor.constraint(equalToConstant: 36)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Helpers
    
    func configure(title: String, placeholder: String) {
        self.titleLabel.text = title
        self.valueTextField.placeholder = placeholder
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
