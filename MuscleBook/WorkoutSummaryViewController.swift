/*
 Muscle Book
 Copyright (C) 2016  Cristian Filipov

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import UIKit
import Eureka

final class WorkoutSummaryViewController: FormViewController {

    private let db = DB.sharedInstance

    private let workout: Workout

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .Right
        label.font = UIFont.systemFontOfSize(20)
        label.text = self.dateFormatter.stringFromDate(self.workout.startTime)
        return label
    }()
    
    let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .FullStyle
        return formatter
    }()

    let numberFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .DecimalStyle
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    let percentFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .PercentStyle
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    lazy var worksetsSection: Section = {
        let worksets = try! self.db.worksets(workoutID: self.workout.workoutID)
        var section = Section("Sets")
        section += worksets.map(self.workoutRecordToRow)
        return section
    }()

    private let timeFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.timeStyle = .ShortStyle
        return formatter
    }()

    init(workout: Workout) {
        self.workout = workout
        super.init(style: .Grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Workout Summary"

        /* TODO: Not supporting adding sets to past workouts for now */
        if db.count(Workout.self, after: workout.startTime) == 0 {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .Add,
                target: self,
                action: #selector(onAddButtonPressed)
            )
        }

        form

        +++ Section("Summary")

        <<< DateRow() {
            $0.title = "Date"
            $0.tag = "date"
            $0.dateFormatter = self.dateFormatter
        }

        <<< DateRow() {
            $0.title = "Time"
            $0.tag = "time"
            $0.dateFormatter = self.timeFormatter
        }

        <<< SideBySideAnatomyViewRow("anatomy")

        <<< IntRow() {
            $0.title = "Total Volume"
            $0.tag = "total_volume"
            $0.hidden = "$total_volume == nil"
            $0.formatter = self.numberFormatter
        }

        <<< DecimalRow() {
            $0.tag = "ave_rel_volume"
            $0.title = "Ave Pct. Volume"
            $0.hidden = "$ave_rel_volume == nil"
            $0.formatter = self.percentFormatter
        }

        <<< DecimalRow() {
            $0.title = "Ave Intensity"
            $0.tag = "ave_intensity"
            $0.hidden = "$ave_intensity == nil"
            $0.formatter = self.percentFormatter
        }

        <<< DecimalRow() {
            $0.title = "Active Time (min)"
            $0.tag = "active_duration"
            $0.hidden = "$active_duration == nil"
            $0.formatter = self.numberFormatter
        }

        <<< DecimalRow() {
            $0.title = "Rest Time (min)"
            $0.tag = "rest_duration"
            $0.hidden = "$rest_duration == nil"
            $0.formatter = self.numberFormatter
        }

        <<< DecimalRow() {
            $0.title = "Total Time (min)"
            $0.tag = "total_duration"
            $0.hidden = "$total_duration == nil"
            $0.formatter = self.numberFormatter
        }

        <<< LabelRow() {
            $0.title = "Max Activation"
            $0.tag = "activation"
            $0.hidden = "$activation == nil"
        }

        form +++ worksetsSection

        updateRows()
    }

    private func updateRows() {
        form.rowByTag("date")?.value = workout.startTime
        form.rowByTag("time")?.value = workout.startTime
        form.rowByTag("total_volume")?.value = workout.volume
        form.rowByTag("ave_rel_volume")?.value = workout.avePercentMaxVolume
        form.rowByTag("ave_intensity")?.value = workout.aveIntensity
        form.rowByTag("active_duration")?.value = workout.activeDuration / 60
        form.rowByTag("rest_duration")?.value = workout.restDuration / 60
        form.rowByTag("total_duration")?.value = workout.restDuration / 60
        form.rowByTag("activation")?.value = workout.maxActivation.name
        form.rowByTag("anatomy")?.value = try! AnatomyViewConfig(
            db.get(MuscleWorkSummary.self, workoutID: workout.workoutID, movementClass: .Target)
        )
        form.rowByTag("anatomy")?.updateCell()
    }

    private func workoutRecordToRow(workset: Workset) -> BaseRow {
        let row = LabelRow()
        row.title = workset.input.exerciseName
        row.value = workset.shortString
        row.onCellSelection { cell, row in
            let vc = WorksetViewController(workset: workset)
            self.showViewController(vc, sender: nil)
        }
        row.cellSetup { cell, row in
            cell.accessoryType = .DisclosureIndicator
        }
        return row
    }

    func onAddButtonPressed() {
        let vc = WorksetViewController { record in
            self.dismissViewControllerAnimated(true, completion: nil)
            self.updateRows()
        }
        presentModalViewController(vc)
    }

}