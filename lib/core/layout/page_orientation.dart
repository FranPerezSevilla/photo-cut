/// Physical page orientation selected by the sheet layout engine.
enum PageOrientation { portrait, landscape }

/// User preference for page orientation.
///
/// Automatic keeps Photo Cut's existing optimization: both portrait and
/// landscape candidates are evaluated and the highest-capacity layout wins.
enum PageOrientationPreference { automatic, portrait, landscape }
