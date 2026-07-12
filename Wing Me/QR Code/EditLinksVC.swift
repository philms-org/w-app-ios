import UIKit

class EditLinksVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var rowFields:   [UITextField] = []
    private var rowSwitches: [UISwitch] = []
    private var methods:     [WAPContactMethod] = []

    private static let slots: [(type: String, label: String)] = [
        ("whatsapp",  "WhatsApp"),
        ("linkedin",  "LinkedIn"),
        ("facebook",  "Facebook"),
        ("instagram", "Instagram"),
        ("phone",     "Phone"),
        ("link",      "Link / Website"),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.subviews.forEach { $0.removeFromSuperview() }
        view.backgroundColor = .systemBackground
        setupHeader()
        setupTableView()
        loadMethods()
    }

    // MARK: - Layout

    private func setupHeader() {
        let close = UIButton(type: .system)
        close.setTitle("✕", for: .normal)
        close.titleLabel?.font = .systemFont(ofSize: 20)
        close.translatesAutoresizingMaskIntoConstraints = false
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let save = UIButton(type: .system)
        save.setTitle("Save", for: .normal)
        save.titleLabel?.font = .boldSystemFont(ofSize: 17)
        save.translatesAutoresizingMaskIntoConstraints = false
        save.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        save.tag = 99  // tag used in saveTapped to re-enable after async

        view.addSubview(close)
        view.addSubview(save)
        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            save.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            save.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SlotCell")
        tableView.rowHeight = 70
        tableView.separatorInset = .zero
        tableView.allowsSelection = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - Data

    private func loadMethods() {
        guard let uid = WAPAuth.currentUserID else { return }
        Task { @MainActor in
            do {
                let fetched = try await WAPData.shared.fetchContactMethods(userId: uid)
                methods = EditLinksVC.slots.enumerated().map { i, slot in
                    fetched.first { $0.type == slot.type }
                        ?? WAPContactMethod(id: "", userId: uid,
                                           slotOrder: i + 1, type: slot.type,
                                           value: nil, isEnabled: false)
                }
                tableView.reloadData()
            } catch {
                AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
            }
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        EditLinksVC.slots.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SlotCell", for: indexPath)
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let slot   = EditLinksVC.slots[indexPath.row]
        let method = methods.isEmpty ? nil : methods[indexPath.row]

        let icon = UIImageView(image: UIImage(named: LinkCell.assetName(for: slot.type)))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 32).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 32).isActive = true

        let label = UILabel()
        label.text = slot.label
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.widthAnchor.constraint(equalToConstant: 90).isActive = true

        let field = UITextField()
        field.placeholder = slot.type == "phone" ? "+1 234 567 8900" : "URL or handle"
        field.text = method?.value ?? ""
        field.font = .systemFont(ofSize: 13)
        field.borderStyle = .roundedRect
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.keyboardType = slot.type == "phone" ? .phonePad : .URL
        field.tag = indexPath.row

        let toggle = UISwitch()
        toggle.isOn = method?.isEnabled ?? false
        toggle.tag = indexPath.row
        toggle.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)

        // Ensure arrays are large enough
        while rowFields.count   <= indexPath.row { rowFields.append(UITextField()) }
        while rowSwitches.count <= indexPath.row { rowSwitches.append(UISwitch()) }
        rowFields[indexPath.row]   = field
        rowSwitches[indexPath.row] = toggle

        let stack = UIStackView(arrangedSubviews: [icon, label, field, toggle])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            stack.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
        ])
        return cell
    }

    // MARK: - Actions

    @objc private func switchChanged(_ sender: UISwitch) {
        guard sender.tag < methods.count else { return }
        methods[sender.tag].isEnabled = sender.isOn
    }

    @objc private func saveTapped() {
        guard let uid = WAPAuth.currentUserID else { return }
        view.endEditing(true)

        // Capture text field values into methods array
        for (i, field) in rowFields.enumerated() where i < methods.count {
            let text = field.text ?? ""
            methods[i].value = text.isEmpty ? nil : text
        }

        if let saveBtn = view.viewWithTag(99) as? UIButton { saveBtn.isEnabled = false }

        Task { @MainActor in
            do {
                for (i, method) in methods.enumerated() {
                    let isNew   = method.id.isEmpty
                    let hasValue = !(method.value ?? "").isEmpty
                    guard !isNew || hasValue else { continue }   // skip empty new slots
                    var m = method
                    if isNew {
                        m = WAPContactMethod(id: UUID().uuidString, userId: uid,
                                            slotOrder: i + 1, type: m.type,
                                            value: m.value, isEnabled: m.isEnabled)
                    }
                    try await WAPData.shared.upsertContactMethod(m)
                }
                dismiss(animated: true)
            } catch {
                if let saveBtn = view.viewWithTag(99) as? UIButton { saveBtn.isEnabled = true }
                AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
            }
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
