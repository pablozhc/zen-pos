class PosSettings {
  bool requirePersonCount;
  bool warnUnattendedGuests;
  int unattendedGuestsMinutes;
  bool showTipOnCash;
  bool skipTipOnCard;
  bool quickPayment;
  bool largeIcons;
  bool tableMap;
  bool smallPrintFormat;
  bool printWithoutHeader;
  List<String> paymentTypes;

  PosSettings({
    this.requirePersonCount = false,
    this.warnUnattendedGuests = false,
    this.unattendedGuestsMinutes = 30,
    this.showTipOnCash = true,
    this.skipTipOnCard = false,
    this.quickPayment = false,
    this.largeIcons = false,
    this.tableMap = false,
    this.smallPrintFormat = false,
    this.printWithoutHeader = false,
    List<String>? paymentTypes,
  }) : paymentTypes = paymentTypes ?? ['card', 'cash'];

  Map<String, dynamic> toJson() => {
        'requirePersonCount': requirePersonCount,
        'warnUnattendedGuests': warnUnattendedGuests,
        'unattendedGuestsMinutes': unattendedGuestsMinutes,
        'showTipOnCash': showTipOnCash,
        'skipTipOnCard': skipTipOnCard,
        'quickPayment': quickPayment,
        'largeIcons': largeIcons,
        'tableMap': tableMap,
        'smallPrintFormat': smallPrintFormat,
        'printWithoutHeader': printWithoutHeader,
        'paymentTypes': paymentTypes,
      };

  factory PosSettings.fromJson(Map<String, dynamic> json) => PosSettings(
        requirePersonCount: json['requirePersonCount'] ?? false,
        warnUnattendedGuests: json['warnUnattendedGuests'] ?? false,
        unattendedGuestsMinutes: json['unattendedGuestsMinutes'] ?? 30,
        showTipOnCash: json['showTipOnCash'] ?? true,
        skipTipOnCard: json['skipTipOnCard'] ?? false,
        quickPayment: json['quickPayment'] ?? false,
        largeIcons: json['largeIcons'] ?? false,
        tableMap: json['tableMap'] ?? false,
        smallPrintFormat: json['smallPrintFormat'] ?? false,
        printWithoutHeader: json['printWithoutHeader'] ?? false,
        paymentTypes: List<String>.from(json['paymentTypes'] ?? ['card', 'cash']),
      );

  PosSettings copyWith({
    bool? requirePersonCount,
    bool? warnUnattendedGuests,
    int? unattendedGuestsMinutes,
    bool? showTipOnCash,
    bool? skipTipOnCard,
    bool? quickPayment,
    bool? largeIcons,
    bool? tableMap,
    bool? smallPrintFormat,
    bool? printWithoutHeader,
    List<String>? paymentTypes,
  }) =>
      PosSettings(
        requirePersonCount: requirePersonCount ?? this.requirePersonCount,
        warnUnattendedGuests: warnUnattendedGuests ?? this.warnUnattendedGuests,
        unattendedGuestsMinutes:
            unattendedGuestsMinutes ?? this.unattendedGuestsMinutes,
        showTipOnCash: showTipOnCash ?? this.showTipOnCash,
        skipTipOnCard: skipTipOnCard ?? this.skipTipOnCard,
        quickPayment: quickPayment ?? this.quickPayment,
        largeIcons: largeIcons ?? this.largeIcons,
        tableMap: tableMap ?? this.tableMap,
        smallPrintFormat: smallPrintFormat ?? this.smallPrintFormat,
        printWithoutHeader: printWithoutHeader ?? this.printWithoutHeader,
        paymentTypes: paymentTypes ?? this.paymentTypes,
      );
}
