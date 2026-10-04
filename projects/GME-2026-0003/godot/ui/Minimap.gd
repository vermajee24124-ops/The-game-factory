extends Control

## Lightweight racing minimap inspired by open-source Godot racing projects.
## It draws the already-generated finite track, so there is no extra scene or
## physics cost and no external runtime dependency.

var track_points:Array[Vector2]=[]
var player_ratio:=0.0
var checkpoint_ratios:Array[float]=[0.25,0.50,0.75]
var _bounds:=Rect2()

func set_track(points:Array[Vector3])->void:
    track_points.clear()
    if points.is_empty():
        queue_redraw()
        return
    var min_x:=INF
    var max_x:=-INF
    var min_z:=INF
    var max_z:=-INF
    for p in points:
        var v:=Vector2(p.x,p.z)
        track_points.append(v)
        min_x=minf(min_x,v.x)
        max_x=maxf(max_x,v.x)
        min_z=minf(min_z,v.y)
        max_z=maxf(max_z,v.y)
    var pad:=24.0
    _bounds=Rect2(min_x-pad,min_z-pad,maxf(1.0,max_x-min_x+pad*2.0),maxf(1.0,max_z-min_z+pad*2.0))
    queue_redraw()

func set_progress(progress:float,total_length:float)->void:
    player_ratio=clampf(progress/maxf(total_length,1.0),0.0,1.0)
    queue_redraw()

func _map_point(p:Vector2)->Vector2:
    var n:=Vector2(
        (p.x-_bounds.position.x)/maxf(_bounds.size.x,1.0),
        (p.y-_bounds.position.y)/maxf(_bounds.size.y,1.0)
    )
    return Vector2(n.x*size.x,(1.0-n.y)*size.y)

func _point_at_ratio(ratio:float)->Vector2:
    if track_points.size()<2:
        return Vector2(size.x*0.5,size.y*0.5)
    var target:=lerpf(_bounds.position.x,_bounds.end.x,0.5)
    var total_span:float=0.0
    for i in range(track_points.size()-1):
        total_span+=track_points[i].distance_to(track_points[i+1])
    var wanted:=clampf(ratio,0.0,1.0)*total_span
    var run:=0.0
    for i in range(track_points.size()-1):
        var seg:=track_points[i].distance_to(track_points[i+1])
        if run+seg>=wanted:
            var t:=0.0 if is_zero_approx(seg) else (wanted-run)/seg
            return _map_point(track_points[i].lerp(track_points[i+1],t))
        run+=seg
    return _map_point(track_points.back())

func _draw()->void:
    draw_style_box(_panel_style(),Rect2(Vector2.ZERO,size))
    if track_points.size()<2:
        return
    var mapped:=PackedVector2Array()
    mapped.resize(track_points.size())
    for i in range(track_points.size()):
        mapped[i]=_map_point(track_points[i])
    if mapped.size()>=2:
        draw_polyline(mapped,Color(0.65,0.72,0.82,0.72),7.0,true)
        draw_polyline(mapped,Color(0.10,0.16,0.24,1.0),3.0,true)

    for ratio in checkpoint_ratios:
        var cp:=_point_at_ratio(ratio)
        draw_circle(cp,5.0,Color(0.23,0.83,1.0,0.85))
        draw_circle(cp,9.0,Color(0.23,0.83,1.0,0.16))

    var start:=_point_at_ratio(0.0)
    var finish:=_point_at_ratio(1.0)
    draw_circle(start,6.0,Color(1.0,0.70,0.18,0.95))
    draw_circle(finish,6.0,Color(0.23,0.83,0.47,0.95))

    var player:=_point_at_ratio(player_ratio)
    draw_circle(player,9.0,Color(1.0,0.42,0.17,1.0))
    draw_circle(player,4.0,Color(1,1,1,1))

func _panel_style()->StyleBoxFlat:
    var s:=StyleBoxFlat.new()
    s.bg_color=Color(0.03,0.05,0.09,0.86)
    s.corner_radius_top_left=18
    s.corner_radius_top_right=18
    s.corner_radius_bottom_left=18
    s.corner_radius_bottom_right=18
    s.border_width_left=1
    s.border_width_top=1
    s.border_width_right=1
    s.border_width_bottom=1
    s.border_color=Color(1,1,1,0.10)
    return s
