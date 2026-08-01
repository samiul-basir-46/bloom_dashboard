import 'package:flutter/material.dart';

/// Contains useful spacing and helper widgets for layout
final class UIHelper {
  UIHelper._();
  
  static double get _verticalSpaceSmall => 10.0;
  static double get _verticalSpaceMedium => 20.0;
  static double get _verticalSpaceMediumLarge => 25.0;
  static double get _verticalSpaceSemiLarge => 40.0;
  static double get _verticalSpaceLarge => 60.0;
  static double get _verticalSpaceExtraLarge => 100.0;

  static double get _horizontalSpaceSmall => 10.0;
  static double get _horizontalSpaceMedium => 20.0;
  static double get _horizontalSpaceSemiLarge => 40.0;
  static double get _horizontalSpaceLarge => 60.0;

  static Widget get verticalSpaceSmall => SizedBox(height: _verticalSpaceSmall);
  static Widget get verticalSpaceMedium => SizedBox(height: _verticalSpaceMedium);
  static Widget get verticalSpaceMediumLarge =>
      SizedBox(height: _verticalSpaceMediumLarge);
  static Widget get verticalSpaceSemiLarge =>
      SizedBox(height: _verticalSpaceSemiLarge);
  static Widget get verticalSpaceLarge => SizedBox(height: _verticalSpaceLarge);
  static Widget get verticalSpaceExtraLarge =>
      SizedBox(height: _verticalSpaceExtraLarge);

  static Widget get horizontalSpaceSmall => SizedBox(width: _horizontalSpaceSmall);
  static Widget get horizontalSpaceMedium => SizedBox(width: _horizontalSpaceMedium);
  static Widget get horizontalSpaceSemiLarge =>
      SizedBox(width: _horizontalSpaceSemiLarge);
  static Widget get horizontalSpaceLarge => SizedBox(width: _horizontalSpaceLarge);

  static Widget horizontalSpace(double width) => SizedBox(width: width);
  static Widget verticalSpace(double height) => SizedBox(height: height);

  static double kDefaulutPadding() => 20.0;
}
