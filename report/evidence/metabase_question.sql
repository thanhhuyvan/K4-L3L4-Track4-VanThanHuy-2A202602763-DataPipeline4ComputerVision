select drive_id, trip_id, frames, frames_kept, round(100.0*(frames-frames_kept)/nullif(frames,0),1) as dropped_pct from marts.mart_trip_summary order by dropped_pct desc, trip_id;
