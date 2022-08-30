class AppVersions {
  List<AppVersion>? android;
  List<AppVersion>? mac;
  List<AppVersion>? win;

  AppVersions({this.android, this.mac, this.win});

  AppVersions.fromJson(Map<String, dynamic> json) {
    if (json['android'] != null) {
      android = <AppVersion>[];
      json['android'].forEach((v) {
        android!.add(new AppVersion.fromJson(v));
      });
    }
    if (json['mac'] != null) {
      mac = <AppVersion>[];
      json['mac'].forEach((v) {
        mac!.add(new AppVersion.fromJson(v));
      });
    }
    if (json['win'] != null) {
      win = <AppVersion>[];
      json['win'].forEach((v) {
        win!.add(new AppVersion.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.android != null) {
      data['android'] = this.android!.map((v) => v.toJson()).toList();
    }
    if (this.mac != null) {
      data['mac'] = this.mac!.map((v) => v.toJson()).toList();
    }
    if (this.win != null) {
      data['win'] = this.win!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class AppVersion {
  String? versionName;
  String? versionCode;
  String? platform;
  String? appName;
  String? releaseAt;
  String? desc;
  String? downloadLink;

  AppVersion(
      {this.versionName,
      this.versionCode,
      this.platform,
      this.appName,
      this.releaseAt,
      this.desc,
      this.downloadLink});


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppVersion &&
          runtimeType == other.runtimeType &&
          versionName == other.versionName &&
          versionCode == other.versionCode &&
          platform == other.platform &&
          appName == other.appName &&
          releaseAt == other.releaseAt &&
          desc == other.desc &&
          downloadLink == other.downloadLink;

  @override
  int get hashCode =>
      versionName.hashCode ^
      versionCode.hashCode ^
      platform.hashCode ^
      appName.hashCode ^
      releaseAt.hashCode ^
      desc.hashCode ^
      downloadLink.hashCode;

  AppVersion.fromJson(Map<String, dynamic> json) {
    versionName = json['versionName'];
    versionCode = json['versionCode'];
    platform = json['platform'];
    appName = json['appName'];
    releaseAt = json['releaseAt'];
    desc = json['desc'];
    downloadLink = json['downloadLink'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['versionName'] = this.versionName;
    data['versionCode'] = this.versionCode;
    data['platform'] = this.platform;
    data['appName'] = this.appName;
    data['releaseAt'] = this.releaseAt;
    data['desc'] = this.desc;
    data['downloadLink'] = this.downloadLink;
    return data;
  }
}

