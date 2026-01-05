import 'package:flutter/material.dart';
import 'matchmaking_service.dart';

class GlobalState {
  static final ValueNotifier<bool> isMatching = ValueNotifier<bool>(false);
  static final MatchmakingService matchmakingService = MatchmakingService();
}
