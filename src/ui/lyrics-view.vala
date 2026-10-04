namespace G4 {

    public class LyricsLine {
        public double time;
        public string text;
        public Gtk.Label label;

        public LyricsLine (double time, string text) {
            this.time = time;
            this.text = text;
            this.label = new Gtk.Label (text);
            this.label.wrap = true;
            this.label.justify = Gtk.Justification.CENTER;
            this.label.add_css_class ("title-2");
            this.label.add_css_class ("dim-label");
            var attrs = new Pango.AttrList ();
            attrs.insert (Pango.attr_family_new ("Mukta, Mukta Mahee"));
            this.label.attributes = attrs;
            this.label.margin_top = 12;
            this.label.margin_bottom = 12;
        }
    }

    public class LyricsView : Gtk.Box {
        private Gtk.ScrolledWindow _scrolled_window;
        private Gtk.Box _box;
        private Application _app;
        private GenericArray<LyricsLine> _lines = new GenericArray<LyricsLine> ();
        private int _current_line_index = -1;
        private string? _current_lyrics = null;
        private Adw.TimedAnimation? _scroll_anim = null;

        public LyricsView (Application app) {
            _app = app;
            this.orientation = Gtk.Orientation.VERTICAL;
            this.hexpand = true;
            this.vexpand = true;

            _scrolled_window = new Gtk.ScrolledWindow ();
            _scrolled_window.hscrollbar_policy = Gtk.PolicyType.NEVER;
            _scrolled_window.vscrollbar_policy = Gtk.PolicyType.EXTERNAL;
            _scrolled_window.hexpand = true;
            _scrolled_window.vexpand = true;
            this.append (_scrolled_window);

            _box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            _box.halign = Gtk.Align.CENTER;
            _box.valign = Gtk.Align.START;
            _box.margin_start = 24;
            _box.margin_end = 24;
            _box.margin_top = 24;
            _box.margin_bottom = 24;

            _scrolled_window.child = _box;

            app.music_changed.connect (on_music_changed);
            app.player.position_updated.connect (on_position_updated);
            
            on_music_changed (app.current_music);
        }

        private void on_music_changed (Music? music) {
            var new_lyrics = music?.lyrics;
            if (_current_lyrics == new_lyrics)
                return;
                
            _current_lyrics = new_lyrics;
            _lines.remove_range (0, _lines.length);
            _current_line_index = -1;
            
            var child = _box.get_first_child ();
            while (child != null) {
                var next = ((!)child).get_next_sibling ();
                _box.remove ((!)child);
                child = next;
            }

            if (new_lyrics != null && ((!)new_lyrics).length > 0) {
                parse_lrc ((!)new_lyrics);
            }

            if (_lines.length == 0) {
                var label = new Gtk.Label (_("No lyrics available"));
                label.add_css_class ("title-2");
                label.add_css_class ("dim-label");
                _box.append (label);
            } else {
                for (int i = 0; i < _lines.length; i++) {
                    _box.append (_lines[i].label);
                }
            }
            _scrolled_window.get_vadjustment ().set_value (0);
        }

        private double parse_time (string time_str) {
            var parts = time_str.split (":");
            if (parts.length >= 2) {
                int min = int.parse (parts[0]);
                var sec_parts = parts[1].split (".");
                int sec = int.parse (sec_parts[0]);
                int msec = sec_parts.length > 1 ? int.parse (sec_parts[1]) : 0;
                if (sec_parts.length > 1 && sec_parts[1].length == 2) msec *= 10;
                return min * 60.0 + sec + msec / 1000.0;
            }
            return 0;
        }

        private void parse_lrc (string lyrics) {
            var lines = lyrics.split ("\n");
            foreach (var line in lines) {
                var str = line.strip ();
                while (str.has_prefix ("[")) {
                    var end_idx = str.index_of_char (']');
                    if (end_idx > 0) {
                        var time_str = str.substring (1, end_idx - 1);
                        var text = str.substring (end_idx + 1).strip ();
                        var time = parse_time (time_str);
                        if (time > 0 || time_str.has_prefix("00:00")) {
                            _lines.add (new LyricsLine (time, text));
                        }
                        // Handle multiple tags like [00:10.00][00:20.00] text
                        if (text.has_prefix ("[")) {
                            str = text;
                        } else {
                            break;
                        }
                    } else {
                        break;
                    }
                }
            }
            // Sort by time
            _lines.sort_with_data ((a, b) => {
                var la = (LyricsLine) a;
                var lb = (LyricsLine) b;
                if (la.time < lb.time) return -1;
                if (la.time > lb.time) return 1;
                return 0;
            });
        }

        private void on_position_updated (Gst.ClockTime position) {
            if (_lines.length == 0 || !this.get_mapped ()) return;
            
            // Check if unsynced
            if (_lines.length > 0 && _lines[0].time == 0 && _lines[_lines.length - 1].time == 0) return;

            double time = GstPlayer.to_second (position);
            int new_index = -1;
            
            for (int i = 0; i < _lines.length; i++) {
                if (time >= _lines[i].time) {
                    new_index = i;
                } else {
                    break;
                }
            }

            if (new_index != _current_line_index && new_index >= 0) {
                if (_current_line_index >= 0 && _current_line_index < _lines.length) {
                    var old_label = _lines[_current_line_index].label;
                    old_label.remove_css_class ("title-1");
                    old_label.add_css_class ("title-2");
                    old_label.add_css_class ("dim-label");
                }
                
                if (new_index >= 0 && new_index < _lines.length) {
                    var new_label = _lines[new_index].label;
                    new_label.remove_css_class ("title-2");
                    new_label.remove_css_class ("dim-label");
                    new_label.add_css_class ("title-1");
                    
                    var adj = _scrolled_window.get_vadjustment ();
                    Graphene.Rect rect;
                    if (new_label.compute_bounds (_box, out rect)) {
                        double label_y = rect.origin.y + _box.margin_top;
                        double page_size = adj.page_size;
                        double target_value = label_y - (page_size / 2) + (new_label.get_height () / 2);
                        target_value = double.max (adj.lower, double.min (target_value, adj.upper - adj.page_size));
                        
                        if (_scroll_anim != null) {
                            ((!)_scroll_anim).pause ();
                        }
                        var target = new Adw.CallbackAnimationTarget ((value) => {
                            adj.set_value (value);
                        });
                        _scroll_anim = new Adw.TimedAnimation (_scrolled_window, adj.get_value (), target_value, 500, target);
                        ((!)_scroll_anim).easing = Adw.Easing.EASE_IN_OUT_CUBIC;
                        ((!)_scroll_anim).play ();
                    }
                }
                _current_line_index = new_index;
            }
        }
    }
}
