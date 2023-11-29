import SwiftUI

extension AutoISFConf {
    final class StateModel: BaseStateModel<Provider>, PreferencesSettable {
        private(set) var preferences = Preferences()
        @Injected() var settings: SettingsManager!
        @Injected() var storage: FileStorage!

        @Published var unit: GlucoseUnits = .mmolL
        @Published var sections: [FieldSection] = []
        @Published var autoisf: Bool = false

        override func subscribe() {
            unit = settingsManager.settings.units
            preferences = provider.preferences
            autoisf = settings.preferences.autoisf

            // MARK: - autoISF fields

            let autoisfConfig = [
                Field(
                    displayName: "Temp Targets toggle SMB for autoISF",
                    type: .boolean(keypath: \.enableSMBEvenOnOddOff),
                    infoText: NSLocalizedString(
                        "Defaults to false. If true, autoISF will block SMB's when odd TempTargets are used (lower boundary) and enforce SMB, when even TempTargets are used. autoISF is still active and adjusting ISF's. In case of exercise_mode or high_temptarget_raises_sensitivity being true and any High TT being active, it adjusts the oref calculataed ISF, not profile ISF. Only appliccable if autoISF is enabled.",
                        comment: "Odd TT disable SMB"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "Odd Profile Target disables SMB for autoISF",
                    type: .boolean(keypath: \.enableSMBEvenOnOddOffalways),
                    infoText: NSLocalizedString(
                        "Defaults to false. If true, autoISF will block SMB's when odd ProfileTargets are used (lower boundary = upper boundary)",
                        comment: "Odd Target disable SMB"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "Excercise toggles all autoISF adjustments off",
                    type: .boolean(keypath: \.autoISFoffSport),
                    infoText: NSLocalizedString(
                        "Defaults to true. When true, switches off complete autoISF during high TT in excercise mode.",
                        comment: "Switch off autoISF with exercise"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "Exercise Mode",
                    type: .boolean(keypath: \.exerciseMode),
                    infoText: NSLocalizedString(
                        "Defaults to false. When true, > 100 mg/dL high temp target adjusts sensitivityRatio for exercise mode. Synonym for high_temptarget_raises_sensitivity",
                        comment: "Exercise Mode"
                    ),
                    settable: self
                ),
                Field(
                    displayName: NSLocalizedString("Half Basal Exercise Target", comment: "Half Basal Exercise Target") +
                        " (mg/dL)",
                    type: .decimal(keypath: \.halfBasalExerciseTarget),
                    infoText: NSLocalizedString(
                        "Set to a number in mg/dl, e.g. 160, which means when TempTarget (TT) is 160 mg/dL and exercise mode = true, it will run 50% basal at this TT level (if high TT at 120 = 75%; 140 = 60%). This can be adjusted, to give you more control over your exercise modes.",
                        comment: "Half Basal Exercise Target"
                    ),
                    settable: self
                )
            ]

            let xpmToogles = [
                Field(
                    displayName: "Enable BG acceleration",
                    type: .boolean(keypath: \.enableBGacceleration),
                    infoText: NSLocalizedString(
                        "Enables the BG acceleration adaptiions for autoISF\n\nRead up on:\nhttps://github.com/ga-zelle/autoISF/tree/2.8.2dev_ai2.2",
                        comment: "Enable BG accel in autoISF"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "autoISF IOB Threshold",
                    type: .decimal(keypath: \.iobThreshold),
                    infoText: NSLocalizedString(
                        "Safety setting: Amount of IOB that if surpassed will prevent any further SMB's being administered. Default is 0, which disables the IOB threshold for SMB's. Advisable to set to 70% of maxIOB, can be meal dependant.",
                        comment: "autoISF IOB threshold"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "autoISF Max",
                    type: .decimal(keypath: \.autoISFmax),
                    infoText: NSLocalizedString(
                        "Multiplier cap on how high the autoISF ratio can be and therefore how low it can adjust ISF.",
                        comment: "autoISF Max"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "autoISF Min",
                    type: .decimal(keypath: \.autoISFmin),
                    infoText: NSLocalizedString(
                        "This is a multiplier cap for autoISF to set a limit on how low the autoISF ratio can be, which in turn determines how high it can adjust ISF.",
                        comment: "autoISF Min"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "Enable Floating Carbs",
                    type: .boolean(keypath: \.floatingcarbs),
                    infoText: NSLocalizedString(
                        "Defaults to false. If true, then dose slightly more aggressively by using all entered carbs for calculating COBpredBGs. This avoids backing off too quickly as COB decays. Even with this option, oref0 still switches gradually from using COBpredBGs to UAMpredBGs proportionally to how many carbs are left as COB. Summary: use all entered carbs in the future for predBGs & don't decay them as COB, only once they are actual.",
                        comment: "Floating Carbs"
                    ),
                    settable: self
                )
            ]
            let xpmDuraISF = [
                Field(
                    displayName: "DuraISF weight",
                    type: .decimal(keypath: \.autoISFhourlyChange),
                    infoText: NSLocalizedString(
                        "Rate at which ISF is reduced per hour assuming BG leveel remains at double target for that time. When value = 1.0, ISF is reduced to 50% after 1 hour of BG level at 2x target.",
                        comment: "autoISF HourlyMaxChange"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "Enable DuraISF effect with COB",
                    type: .boolean(keypath: \.enableautoISFwithCOB),
                    infoText: NSLocalizedString(
                        "Enable DuraISF even if COB is present not just for UAM.",
                        comment: "Enable autoISF with COB"
                    ),
                    settable: self
                )
            ]

            let xpmBGISF = [
                Field(
                    displayName: "ISF weight for higher BG's",
                    type: .decimal(keypath: \.higherISFrangeWeight),
                    infoText: NSLocalizedString(
                        "Default value: 0.0 This is the weight applied to the polygon which adapts ISF if glucose is above target. With 0.0 the effect is effectively disabled.",
                        comment: "ISF high BG weight"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "ISF weight for lower BG's",
                    type: .decimal(keypath: \.lowerISFrangeWeight),
                    infoText: NSLocalizedString(
                        "Default value: 0.0 This is the weight applied to the polygon which adapts ISF if glucose is below target. With 0.0 the effect is effectively disabled.",
                        comment: "ISF low BG weight"
                    ),
                    settable: self
                )
            ]
            let xpmDeltaISF = [
                Field(
                    displayName: "ISF weight for higher BG deltas",
                    type: .decimal(keypath: \.deltaISFrangeWeight),
                    infoText: NSLocalizedString(
                        "Default value: 0.0 This is the weight applied to the polygon which adapts ISF higher deltas. With 0.0 the effect is effectively disabled.",
                        comment: "ISF higher delta BG weight"
                    ),
                    settable: self
                )
            ]

            let xpmAcceISF = [
                Field(
                    displayName: "ISF weight while BG accelerates",
                    type: .decimal(keypath: \.bgAccelISFweight),
                    infoText: NSLocalizedString(
                        "Default value: 0. This is the weight applied while glucose accelerates and which strengthens ISF. With 0 this contribution is effectively disabled. 0.02 is a safe starting point, from which to move up. Typical settings are around 0.15!",
                        comment: "ISF acceleration weight"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "ISF weight while BG decelerates",
                    type: .decimal(keypath: \.bgBrakeISFweight),
                    infoText: NSLocalizedString(
                        "Default value: 0. This is the weight applied while glucose decelerates and which weakens ISF. With 0 this contribution is effectively disabled. 0.1 might be a good starting point.",
                        comment: "ISF decceleration weight"
                    ),
                    settable: self
                )
            ]

            let xpmPostPrandial = [
                Field(
                    displayName: "Enable always postprandial ISF adaption",
                    type: .boolean(keypath: \.postMealISFalways),
                    infoText: NSLocalizedString(
                        "Enable the postprandial ISF adaptation all the time regardless of when the last meal was taken.",
                        comment: "Enable postprandial ISF always"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "ISF weight for postprandial BG rise",
                    type: .decimal(keypath: \.postMealISFweight),
                    infoText: NSLocalizedString(
                        "Default value: 0 This is the weight applied to the linear slope while glucose rises and  which adapts ISF. With 0 this contribution is effectively disabled. Start with 0.01 - it hardly goes beyond 0.05!",
                        comment: "ISF postprandial weight"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "Duration ISF postprandial adaption",
                    type: .decimal(keypath: \.postMealISFduration),
                    infoText: NSLocalizedString(
                        "Default value: 3 This is the duration in hours how long after a meal the effect will be active. Oref will delete carb timing after 10 hours latest no matter what you enter.",
                        comment: "ISF postprandial change duration"
                    ),
                    settable: self
                )
            ]

            let xpmSMB = [
                Field(
                    displayName: "SMB Max RangeExtension",
                    type: .decimal(keypath: \.smbMaxRangeExtension),
                    infoText: NSLocalizedString(
                        "Default value: 1. This is another key OpenAPS safety cap, and specifies by what factor you can exceed the regular 120 maxSMB/maxUAM minutes. Increase this experimental value slowly and with caution. Available only when autoISF is enabled.",
                        comment: "SMB Max RangeExtension"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "SMB DeliveryRatio",
                    type: .decimal(keypath: \.smbDeliveryRatio),
                    infoText: NSLocalizedString(
                        "Default value: 0.5 This is another key OpenAPS safety cap, and specifies what share of the total insulin required can be delivered as SMB. This is to prevent people from getting into dangerous territory by setting SMB requests from the caregivers phone at the same time. Increase this experimental value slowly and with caution. YOu can use that with autoISF to increase the SMB DR immediatly indpendant of BG if you use an Eating Soon TT (even and below 100). This SMB DR will than be used, independantly of the 3 following options, that normally superceed his setting.",
                        comment: "SMB DeliveryRatio"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "SMB DeliveryRatio BG Range",
                    type: .decimal(keypath: \.smbDeliveryRatioBGrange),
                    infoText: NSLocalizedString(
                        "Default value: 0, Sensible is bteween 40 and 120. The linearly increasing SMB delivery ratio is mapped to the glucose range [target_bg, target_bg+bg_range]. At target_bg the SMB ratio is smb_delivery_ratio_min, at target_bg+bg_range it is smb_delivery_ratio_max. With 0 the linearly increasing SMB ratio is disabled and the fix smb_delivery_ratio is used.",
                        comment: "SMB DeliveryRatio BG Range"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "SMB DeliveryRatio BG Minimum",
                    type: .decimal(keypath: \.smbDeliveryRatioMin),
                    infoText: NSLocalizedString(
                        "Default value: 0.5 This is the lower end of a linearly increasing SMB Delivery Ratio rather than the fix value above in SMB DeliveryRatio.",
                        comment: "SMB DeliveryRatio Minimum"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "SMB DeliveryRatio BG Maximum",
                    type: .decimal(keypath: \.smbDeliveryRatioMax),
                    infoText: NSLocalizedString(
                        "Default value: 0.5 This is the higher end of a linearly increasing SMB Delivery Ratio rather than the fix value above in SMB DeliveryRatio.",
                        comment: "SMB DeliveryRatio Minimum"
                    ),
                    settable: self
                )
            ]

            let xpmB30 = [
                Field(
                    displayName: "Enable B30 EatingSoon",
                    type: .boolean(keypath: \.enableB30),
                    infoText: NSLocalizedString(
                        "Enables an increased basal rate after an EatingSoon TT and a manual bolus to saturate the infusion site with insulin to increase insulin absorption for SMB's following a meal with no carb counting.",
                        comment: "Enable B30 for autoISF"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "TempTarget Level in mg/dl for B30 to be enacted",
                    type: .decimal(keypath: \.B30iTimeTarget),
                    infoText: NSLocalizedString(
                        "An EatingSoon TempTarget needs to be enabled to start B30 adaption. Set level for this target to be identified. Default is 90 mg/dl. If you cancel this EatingSoon TT also the B30 basal rate will stop.",
                        comment: "EatingSoon TT level"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "Minimum Start Bolus size",
                    type: .decimal(keypath: \.B30iTimeStartBolus),
                    infoText: NSLocalizedString(
                        "Minimum manual bolus to start a B30 adaption.",
                        comment: "B30 Start Bolus size"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "Duration of increased B30 basal rate",
                    type: .decimal(keypath: \.B30iTime),
                    infoText: NSLocalizedString(
                        "Duration of increased basal rate that saturates the infusion site with insulin. Default 30 minutes, as in B30. The EatingSoon TT needs to be running at least for this duration, otherthise B30 will stopp after the TT runs out.",
                        comment: "Duration of B30"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "B30 Basal rate increase factor",
                    type: .decimal(keypath: \.B30basalFactor),
                    infoText: NSLocalizedString(
                        "Factor that multiplies your regular basal rate from profile for B30. Default is 10.",
                        comment: "Basal rate factor B30"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "Upper BG limit in mg/dl for B30",
                    type: .decimal(keypath: \.B30upperLimit),
                    infoText: NSLocalizedString(
                        "B30 will only run as long as BG stays underneath that level, if above regular autoISF takes over. Default is 130 mg/dl.",
                        comment: "Upper BG for B30"
                    ),
                    settable: self
                ),
                Field(
                    displayName: "Upper Delta limit in mg/dl for B30",
                    type: .decimal(keypath: \.B30upperDelta),
                    infoText: NSLocalizedString(
                        "B30 will only run as long as BG delta stays below that level, if above regular autoISF takes over. Default is 8 mg/dl.",
                        comment: "Upper Delta for B30"
                    ),
                    settable: self
                )
            ]

            sections = [
                FieldSection(
                    displayName: NSLocalizedString("Target & Exercise Control", comment: "AutoISF control via Targets"),
                    fields: autoisfConfig
                ),
                FieldSection(
                    displayName: NSLocalizedString(
                        "Toggles & general Settings",
                        comment: "Switch on/off experimental stuff"
                    ),
                    fields: xpmToogles
                ),
                FieldSection(
                    displayName: NSLocalizedString(
                        "SMB Delivery Ratio settings",
                        comment: "Experimental settings for SMB increases autoISF 2.0"
                    ),
                    fields: xpmSMB
                ),
                FieldSection(
                    displayName: NSLocalizedString(
                        "B30 settings",
                        comment: "AIMI B30  settings"
                    ),
                    fields: xpmB30
                ),
                FieldSection(
                    displayName: NSLocalizedString(
                        "Acce-ISF settings",
                        comment: "Experimental settings for acceleration based autoISF 2.2"
                    ),
                    fields: xpmAcceISF
                ),
                FieldSection(
                    displayName: NSLocalizedString(
                        "BG-ISF settings",
                        comment: "Experimental settings for BG level based autoISF2.1"
                    ),
                    fields: xpmBGISF
                ),
                FieldSection(
                    displayName: NSLocalizedString(
                        "Dura-ISF settings",
                        comment: "Experimental settings for high BG plateau based autoISF2.0"
                    ),
                    fields: xpmDuraISF
                ),
                FieldSection(
                    displayName: NSLocalizedString(
                        "PP-ISF settings",
                        comment: "Experimental settings for postprandial based autoISF 2.2"
                    ),
                    fields: xpmPostPrandial
                ),
                FieldSection(
                    displayName: NSLocalizedString(
                        "Delta-ISF settings",
                        comment: "Experimental settings for BG delta based autoISF2.1"
                    ),
                    fields: xpmDeltaISF
                )
            ]
        }

        func convertBack(_ glucose: Decimal) -> Decimal {
            if unit == .mmolL {
                return glucose.asMgdL
            }
            return glucose
        }

        func save() {
            provider.savePreferences(preferences)
        }

        func set<T>(_ keypath: WritableKeyPath<Preferences, T>, value: T) {
            preferences[keyPath: keypath] = value
            save()
        }

        func get<T>(_ keypath: WritableKeyPath<Preferences, T>) -> T {
            preferences[keyPath: keypath]
        }
    }
}
