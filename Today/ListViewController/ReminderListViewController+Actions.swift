

import UIKit

extension ReminderListViewController {
	@objc func eventStoreChanged(_ notification: NSNotification) {
		reminderStoreChanged()
	}
	
	@objc func didPressDoneButton(_ sender: ReminderDoneButton) {
		guard let id = sender.id else { return }
		completeReminder(withId: id)
	}
	
	@objc func didPressAddButton(_ sender: UIBarButtonItem) {
		let reminder = Reminder(title: "", dueDate: Date.now)
		let viewController = ReminderViewController(reminder: reminder) { [weak self] reminder in
			self?.addReminder(reminder)
			self?.updateSnapshot()
			self?.dismiss(animated: true)
		}
		viewController.isAddingNewReminder = true
		viewController.setEditing(true, animated: false)
		viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
			barButtonSystemItem: .cancel, target: self, action: #selector(didCancelAdd(_:)))
		viewController.navigationItem.title = NSLocalizedString(
			"Add Reminder", comment: "Add Reminder view controller title")
		let navigationController = UINavigationController(rootViewController: viewController)
		present(navigationController, animated: true)
	}
	
	@objc func didCancelAdd(_ sender: UIBarButtonItem) {
		dismiss(animated: true)
	}
	
	@objc func didChangeListStyle(_ sender: UISegmentedControl) {
		listStyle = ReminderListStyle(rawValue: sender.selectedSegmentIndex) ?? .today
		updateSnapshot()
		refreshBackground()
	}
}
