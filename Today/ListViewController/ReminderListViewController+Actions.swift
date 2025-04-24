

import UIKit

extension ReminderListViewController {
	@objc func didPressDoneButton(_ sender: ReminderDoneButton) {
		guard let id = sender.id else { return }
		completeReminder(withId: id)
	}
}


