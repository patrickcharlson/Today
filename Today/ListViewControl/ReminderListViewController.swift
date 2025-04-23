

import UIKit

class ReminderListViewController: UICollectionViewController {
	var dataSource: DataSource?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let listLayout = listLayout()
		collectionView.collectionViewLayout = listLayout
		
		let cellRegistration = UICollectionView.CellRegistration(handler: cellRegistrationHandler)

		dataSource = DataSource(collectionView: collectionView) {
			(collectionView: UICollectionView, indexPath: IndexPath, itemIdentifier: String) -> UICollectionViewCell? in
			return collectionView.dequeueConfiguredReusableCell(
				using: cellRegistration, for: indexPath, item: itemIdentifier)
		}


		var snapshot = Snapshot()
		snapshot.appendSections([0])
		snapshot.appendItems(Reminder.sampleData.map { $0.title })
		dataSource?.apply(snapshot)
	}


	private func listLayout() -> UICollectionViewCompositionalLayout {
		var listConfiguration = UICollectionLayoutListConfiguration(appearance: .grouped)
		listConfiguration.showsSeparators = false
		listConfiguration.backgroundColor = .clear
		return UICollectionViewCompositionalLayout.list(using: listConfiguration)
	}
}
