

import UIKit

extension ReminderListViewController {
	typealias DataSource = UICollectionViewDiffableDataSource<Int, Reminder.ID>
	typealias Snapshot = NSDiffableDataSourceSnapshot<Int, Reminder.ID>
	
	var reminderCompletedValue: String {
		NSLocalizedString("Completed", comment: "Reminder completed value")
	}
	
	var reminderNotCompletedValue: String {
		NSLocalizedString("Not Completed", comment: "Reminder not completed value")
	}
	
	private var reminderStore: ReminderStore { ReminderStore.shared }
	
	func updateSnapshot(reloading ids: [Reminder.ID] = []) {
		var snapshot = Snapshot()
		snapshot.appendSections([0])
		snapshot.appendItems(filteredReminders.map {$0.id})
		if !ids.isEmpty {
			snapshot.reloadItems(ids)
		}
		dataSource?.apply(snapshot)
		headerView?.progress = progress
	}
	
	func cellRegistrationHandler(cell: UICollectionViewListCell, indexPath: IndexPath, id: Reminder.ID) {
		let reminder = reminder(withId: id)
		var contentConfiguration = cell.defaultContentConfiguration()
		contentConfiguration.text = reminder.title
		contentConfiguration.secondaryText = reminder.dueDate.dayAndTimeText
		contentConfiguration.secondaryTextProperties.font = UIFont.preferredFont(forTextStyle: .caption1)
		cell.contentConfiguration = contentConfiguration
		
		var doneButtonConfiguration = doneButtonConfiguration(for: reminder)
		doneButtonConfiguration.tintColor = .todayListCellDoneButtonTint
		cell.accessibilityCustomActions = [doneButtonAccessibilityAction(for: reminder)]
		cell.accessibilityValue = reminder.isComplete ? reminderCompletedValue : reminderNotCompletedValue
		cell.accessories = [.customView(configuration: doneButtonConfiguration), .disclosureIndicator(displayed: .always)]
		
		var backgroundConfiguration = UIBackgroundConfiguration.listCell()
		backgroundConfiguration.backgroundColor = .todayListCellBackground
		cell.backgroundConfiguration = backgroundConfiguration
	}
	
	func reminder(withId id: Reminder.ID) -> Reminder {
		let index = reminders.indexOfReminder(withId: id)
		return reminders[index]
	}
	
	func updateReminder(_ reminder: Reminder) {
		do {
			try reminderStore.save(reminder)
			let index = reminders.indexOfReminder(withId: reminder.id)
			reminders[index] = reminder
		} catch TodayError.accessDenied {
		} catch {
			showError(error)
		}
	}
	
	func completeReminder(withId id: Reminder.ID) {
		var reminder = reminder(withId: id)
		reminder.isComplete.toggle()
		updateReminder(reminder)
		updateSnapshot(reloading: [id])
	}
	
	func addReminder(_ reminder: Reminder) {
		var reminder = reminder
		do {
			let idFromStore = try reminderStore.save(reminder)
			reminder.id = idFromStore
			reminders.append(reminder)
		} catch TodayError.accessDenied {
		} catch {
			showError(error)
		}
	}
	
	func deleteReminder(withId id: Reminder.ID) {
		do {
			try reminderStore.remove(with: id)
			let index = reminders.indexOfReminder(withId: id)
			reminders.remove(at: index)
		} catch TodayError.accessDenied {
		} catch {
			showError(error)
		}
	}
	
	func prepareReminderStore() {
		Task {
			do {
				try await reminderStore.requestAccess()
				reminders = try await reminderStore.readAll()
				NotificationCenter.default.addObserver(
					self, selector: #selector(eventStoreChanged(_:)), name: .EKEventStoreChanged, object: nil)
			} catch TodayError.accessDenied, TodayError.accessRestricted {
				#if DEBUG
					reminders = Reminder.sampleData
				#endif
			} catch {
				showError(error)
			}
			updateSnapshot()
		}
	}
	
	func reminderStoreChanged() {
		Task {
			reminders = try await reminderStore.readAll()
			updateSnapshot()
		}
	}
	
	private func doneButtonAccessibilityAction(for reminder: Reminder) -> UIAccessibilityCustomAction {
		let name = NSLocalizedString(
			"Toggle completion", comment: "Reminder done button accessibility label"
		)
		let action = UIAccessibilityCustomAction(name: name) { [weak self] action in
			self?.completeReminder(withId: reminder.id)
			return true
		}
		return action
	}
	
	private func doneButtonConfiguration(for reminder: Reminder) -> UICellAccessory.CustomViewConfiguration {
		let symbolName = reminder.isComplete ? "circle.fill" : "circle"
		let symbolConfiguration = UIImage.SymbolConfiguration(textStyle: .title1)
		let image = UIImage(systemName: symbolName, withConfiguration: symbolConfiguration)
		let button = ReminderDoneButton()
		button.addTarget(self, action: #selector(didPressDoneButton(_:)), for: .touchUpInside)
		button.id = reminder.id
		button.setImage(image, for: .normal)
		return UICellAccessory.CustomViewConfiguration(customView: button, placement: .leading(displayed: .always))
	}
}
