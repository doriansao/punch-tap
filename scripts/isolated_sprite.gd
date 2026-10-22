extends RefCounted
## Texture-preserving component geometry: neighbouring atlas poses never draw.
var meshes: Dictionary={}
func draw(canvas: CanvasItem, texture: Texture2D, registration: Dictionary, region: Rect2, width: float, scale: float, tint: Color=Color.WHITE) -> void:
 var key=str(registration.texture)+str(region)+str(scale)
 if not meshes.has(key):
  var vertices:=PackedVector3Array();var uv:=PackedVector2Array()
  var origin:=Vector2(registration.region[0],registration.region[1])
  for span in registration.draw_spans:
   var source:=Rect2(origin+Vector2(span[0],span[1]),Vector2(span[2],span[3])).intersection(region)
   if not source.has_area():continue
   var points: Array=[source.position,Vector2(source.end.x,source.position.y),source.end,source.position,source.end,Vector2(source.position.x,source.end.y)]
   for p in points:
    var local: Vector2=(p-region.position)*scale-Vector2(width/2,0)
    vertices.append(Vector3(local.x,local.y,0));uv.append(p/texture.get_size())
  var arrays: Array=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uv
  var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);meshes[key]=mesh
 canvas.draw_mesh(meshes[key],texture,Transform2D.IDENTITY,tint)
