import 'dart:convert';

TokenModel tokenModelFromJson(String str) =>
    TokenModel.fromJson(json.decode(str));

String tokenModelToJson(TokenModel data) => json.encode(data.toJson());

class TokenModel {
  int status;
  String message;
  Data data;

  TokenModel({required this.status, required this.message, required this.data});

  factory TokenModel.fromJson(Map<String, dynamic> json) => TokenModel(
    status: json["status"],
    message: json["message"],
    data: Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data.toJson(),
  };
}

class Data {
  String accessToken;
  String refreshToken;
  User user;

  Data({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    accessToken: json["accessToken"],
    refreshToken: json["refreshToken"],
    user: User.fromJson(json["user"]),
  );

  Map<String, dynamic> toJson() => {
    "accessToken": accessToken,
    "refreshToken": refreshToken,
    "user": user.toJson(),
  };
}

class User {
  String initials;
  String userId;
  dynamic userAccountId;
  String fname;
  String lname;
  String name;
  String email;
  dynamic phone;
  dynamic isActive;
  String userRole;
  String password;
  dynamic oldPassword;
  DateTime lastPwdChange;
  DateTime lastLogin;
  bool otpValidated;
  int otp;
  DateTime otpExpiration;
  String dealerName;
  int dealerCode;
  dynamic dealerLocation;
  dynamic evaluation;
  dynamic icsId;
  dynamic icsPwd;
  String deviceToken;
  dynamic teamName;
  String teamRole;
  bool deleted;
  String dealerId;
  String accessToken;
  String refreshToken;
  dynamic rating;
  dynamic profilePic;
  dynamic reviews;
  dynamic feedbackSubmitted;
  dynamic feedbackComments;
  dynamic excellence;
  dynamic createdAt;
  DateTime updatedAt;
  String corporateId;
  dynamic roleId;
  String teamId;

  User({
    required this.initials,
    required this.userId,
    required this.userAccountId,
    required this.fname,
    required this.lname,
    required this.name,
    required this.email,
    required this.phone,
    required this.isActive,
    required this.userRole,
    required this.password,
    required this.oldPassword,
    required this.lastPwdChange,
    required this.lastLogin,
    required this.otpValidated,
    required this.otp,
    required this.otpExpiration,
    required this.dealerName,
    required this.dealerCode,
    required this.dealerLocation,
    required this.evaluation,
    required this.icsId,
    required this.icsPwd,
    required this.deviceToken,
    required this.teamName,
    required this.teamRole,
    required this.deleted,
    required this.dealerId,
    required this.accessToken,
    required this.refreshToken,
    required this.rating,
    required this.profilePic,
    required this.reviews,
    required this.feedbackSubmitted,
    required this.feedbackComments,
    required this.excellence,
    required this.createdAt,
    required this.updatedAt,
    required this.corporateId,
    required this.roleId,
    required this.teamId,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    initials: json["initials"],
    userId: json["user_id"],
    userAccountId: json["user_account_id"],
    fname: json["fname"],
    lname: json["lname"],
    name: json["name"],
    email: json["email"],
    phone: json["phone"],
    isActive: json["isActive"],
    userRole: json["user_role"],
    password: json["password"],
    oldPassword: json["old_password"],
    lastPwdChange: DateTime.parse(json["last_pwd_change"]),
    lastLogin: DateTime.parse(json["last_login"]),
    otpValidated: json["otp_validated"],
    otp: json["otp"],
    otpExpiration: DateTime.parse(json["otp_expiration"]),
    dealerName: json["dealer_name"],
    dealerCode: json["dealer_code"],
    dealerLocation: json["dealer_location"],
    evaluation: json["evaluation"],
    icsId: json["ics_id"],
    icsPwd: json["ics_pwd"],
    deviceToken: json["device_token"],
    teamName: json["team_name"],
    teamRole: json["team_role"],
    deleted: json["deleted"],
    dealerId: json["dealer_id"],
    accessToken: json["access_token"],
    refreshToken: json["refresh_token"],
    rating: json["rating"],
    profilePic: json["profile_pic"],
    reviews: json["reviews"],
    feedbackSubmitted: json["feedback_submitted"],
    feedbackComments: json["feedback_comments"],
    excellence: json["excellence"],
    createdAt: json["created_at"],
    updatedAt: DateTime.parse(json["updated_at"]),
    corporateId: json["corporate_id"],
    roleId: json["role_id"],
    teamId: json["team_id"],
  );

  Map<String, dynamic> toJson() => {
    "initials": initials,
    "user_id": userId,
    "user_account_id": userAccountId,
    "fname": fname,
    "lname": lname,
    "name": name,
    "email": email,
    "phone": phone,
    "isActive": isActive,
    "user_role": userRole,
    "password": password,
    "old_password": oldPassword,
    "last_pwd_change": lastPwdChange.toIso8601String(),
    "last_login": lastLogin.toIso8601String(),
    "otp_validated": otpValidated,
    "otp": otp,
    "otp_expiration": otpExpiration.toIso8601String(),
    "dealer_name": dealerName,
    "dealer_code": dealerCode,
    "dealer_location": dealerLocation,
    "evaluation": evaluation,
    "ics_id": icsId,
    "ics_pwd": icsPwd,
    "device_token": deviceToken,
    "team_name": teamName,
    "team_role": teamRole,
    "deleted": deleted,
    "dealer_id": dealerId,
    "access_token": accessToken,
    "refresh_token": refreshToken,
    "rating": rating,
    "profile_pic": profilePic,
    "reviews": reviews,
    "feedback_submitted": feedbackSubmitted,
    "feedback_comments": feedbackComments,
    "excellence": excellence,
    "created_at": createdAt,
    "updated_at": updatedAt.toIso8601String(),
    "corporate_id": corporateId,
    "role_id": roleId,
    "team_id": teamId,
  };
}
