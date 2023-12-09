extends ColorRect

######## CONFIG ########
const MAX_ITER = 2
const FOCUS = 2.2
const F_VAL = 14
########################

const DIMENSION_NUM_3 = 3
const DIMENSION_NUM_3_X = 0
const DIMENSION_NUM_3_Y = 1
const DIMENSION_NUM_3_Z = 2

const NUM_SHAPE_MAX = 16
const SHAPE_TYPE_NULL = -1
const SHAPE_TYPE_WALL = 0
const SHAPE_TYPE_SPHERE = 1
const SHAPE_TYPE_CYLINDER = 2
const SHAPE_TYPE_TORUS = 3
const SHAPE_TYPE_NAME = [
	"wall",
	"sphere",
	"cylinder",
	"torus",
]

const SHAPE_OPERATION_NONE = 0
const SHAPE_OPERATION_ASSIGN = 1
const SHAPE_OPERATION_UNION = 2
const SHAPE_OPERATION_INTERSECTION = 3
const SHAPE_OPERATION_DIFF = 4
const SHAPE_OPERATION_NAME = [
	"none",
	"assign",
	"union",
	"intersection",
	"diff",
]

const KEYBOARD_CONTROL_COEFFICIENT = 0.01
const TOUCH_CONTROL_COEFFICIENT = 0.005
var shapes = []

var t: float = 0.0
var sphere

func createPackedFloat32Mat4(init: Array) -> PackedFloat32Array:
	var mat: PackedFloat32Array = PackedFloat32Array()
	mat.resize(16)
	for i in range(16):
		if i < len(init):
			mat[i] = init[i]
		else:
			mat[i] = 0.0
	return mat

func createShapeStructFloor():
	return {
		"type": PackedInt32Array([ SHAPE_TYPE_WALL, SHAPE_TYPE_NULL, SHAPE_TYPE_NULL, SHAPE_TYPE_NULL ]),
		"ope": PackedInt32Array([ SHAPE_OPERATION_ASSIGN, SHAPE_OPERATION_NONE, SHAPE_OPERATION_NONE, SHAPE_OPERATION_NONE ]),
		"va": createPackedFloat32Mat4([ 0.0, -1.5, 0.0, 0.0 ]),
		"vb": createPackedFloat32Mat4([ 0.0, 1.0, 0.0, 0.0 ]),
		"fa": PackedFloat32Array([ 0.0, 0.0, 0.0, 0.0 ]),
		"fb": PackedFloat32Array([ 0.0, 0.0, 0.0, 0.0 ]),
		"col": Vector3(0.1, 0.1, 0.1),
		"ref": Vector3(0.8, 0.8, 0.8),
		"rough": 0.8,
		"f0": 0.9,
		"cr": 0.0,
		"mu": 1.2,
	}

func createShapeStructCeiling():
	return {
		"type": PackedInt32Array([ SHAPE_TYPE_WALL, SHAPE_TYPE_NULL, SHAPE_TYPE_NULL, SHAPE_TYPE_NULL ]),
		"ope": PackedInt32Array([ SHAPE_OPERATION_ASSIGN, SHAPE_OPERATION_NONE, SHAPE_OPERATION_NONE, SHAPE_OPERATION_NONE ]),
		"va": createPackedFloat32Mat4([ 0.0, 1.5, 0.0, 0.0 ]),
		"vb": createPackedFloat32Mat4([ 0.0, -1.0, 0.0, 0.0 ]),
		"fa": PackedFloat32Array([ 0.0, 0.0, 0.0, 0.0 ]),
		"fb": PackedFloat32Array([ 0.0, 0.0, 0.0, 0.0 ]),
		"col": Vector3(0.8, 0.8, 1.2),
		"ref": Vector3(0.2, 0.2, 0.2),
		"rough": 0.8,
		"f0": 0.9,
		"cr": 0.0,
		"mu": 1.2,
	}

func createShapeStructDeepWall():
	return {
		"type": PackedInt32Array([ SHAPE_TYPE_WALL, SHAPE_TYPE_NULL, SHAPE_TYPE_NULL, SHAPE_TYPE_NULL ]),
		"ope": PackedInt32Array([ SHAPE_OPERATION_ASSIGN, SHAPE_OPERATION_NONE, SHAPE_OPERATION_NONE, SHAPE_OPERATION_NONE ]),
		"va": createPackedFloat32Mat4([ 0.0, 0.0, 5.0, 0.0, 0.0 ]),
		"vb": createPackedFloat32Mat4([ 0.0, 0.0, -1.0, 0.0 ]),
		"fa": PackedFloat32Array([ 0.0, 0.0, 0.0, 0.0 ]),
		"fb": PackedFloat32Array([ 0.0, 0.0, 0.0, 0.0 ]),
		"col": Vector3(0.3, 0.0, 0.0),
		"ref": Vector3(0.8, 0.8, 0.8),
		"rough": 0.9,
		"f0": 0.9,
		"cr": 0.0,
		"mu": 1.2,
	}

func createShapeStructBackLight():
	return {
		"type": PackedInt32Array([ SHAPE_TYPE_WALL, SHAPE_TYPE_NULL, SHAPE_TYPE_NULL, SHAPE_TYPE_NULL ]),
		"ope": PackedInt32Array([ SHAPE_OPERATION_ASSIGN, SHAPE_OPERATION_NONE, SHAPE_OPERATION_NONE, SHAPE_OPERATION_NONE ]),
		"va": createPackedFloat32Mat4([ 0.0, 0.0, -1.0, 0.0 ]),
		"vb": createPackedFloat32Mat4([ 0.0, 0.5, 1.0, 0.0 ]),
		"fa": PackedFloat32Array([ 0.0, 0.0, 0.0, 0.0 ]),
		"fb": PackedFloat32Array([ 0.0, 0.0, 0.0, 0.0 ]),
		"col": Vector3(4.0, 2.9, 2.9),
		"ref": Vector3(0.5, 0.5, 0.5),
		"rough": 0.8,
		"f0": 0.9,
		"cr": 0.0,
		"mu": 1.2,
	}

func createShapeStructLeftWall():
	return {
		"type": PackedInt32Array([ SHAPE_TYPE_WALL, SHAPE_TYPE_NULL, SHAPE_TYPE_NULL, SHAPE_TYPE_NULL ]),
		"ope": PackedInt32Array([ SHAPE_OPERATION_ASSIGN, SHAPE_OPERATION_NONE, SHAPE_OPERATION_NONE, SHAPE_OPERATION_NONE ]),
		"va": createPackedFloat32Mat4([ -1.5, 0.0, 0.0, 0.0 ]),
		"vb": createPackedFloat32Mat4([ 1.0, 0.0, 0.5, 0.0 ]),
		"fa": PackedFloat32Array([ 0.0, 0.0, 0.0, 0.0 ]),
		"fb": PackedFloat32Array([ 0.0, 0.0, 0.0, 0.0 ]),
		"col": Vector3(0.25, 0.25, 0.5),
		"ref": Vector3(0.95, 0.95, 0.95),
		"rough": 0.8,
		"f0": 0.9,
		"cr": 0.0,
		"mu": 1.2,
	}

func createShapeStructRightWall():
	return {
		"type": PackedInt32Array([ SHAPE_TYPE_WALL, SHAPE_TYPE_NULL, SHAPE_TYPE_NULL, SHAPE_TYPE_NULL ]),
		"ope": PackedInt32Array([ SHAPE_OPERATION_ASSIGN, SHAPE_OPERATION_NONE, SHAPE_OPERATION_NONE, SHAPE_OPERATION_NONE ]),
		"va": createPackedFloat32Mat4([ 1.5, 0.0, 0.0, 0.0 ]),
		"vb": createPackedFloat32Mat4([ -1.0, 0.0, 0.5, 0.0 ]),
		"fa": PackedFloat32Array([ 0.0, 0.0, 0.0, 0.0 ]),
		"fb": PackedFloat32Array([ 0.0, 0.0, 0.0, 0.0 ]),
		"col": Vector3(0.25, 0.5, 0.25),
		"ref": Vector3(0.925, 0.95, 0.925),
		"rough": 0.8,
		"f0": 0.8,
		"cr": 0.0,
		"mu": 1.2,
	}

func createShapeStructSphere():
	return {
		"type": PackedInt32Array([ SHAPE_TYPE_SPHERE, SHAPE_TYPE_NULL, SHAPE_TYPE_NULL, SHAPE_TYPE_NULL ]),
		"ope": PackedInt32Array([ SHAPE_OPERATION_ASSIGN, SHAPE_OPERATION_NONE, SHAPE_OPERATION_NONE, SHAPE_OPERATION_NONE ]),
		"va": createPackedFloat32Mat4([ -0.8, -0.7, 3.1, 0.0 ]),
		"vb": createPackedFloat32Mat4([ 0.0, 0.0, 0.0, 0.0 ]),
		"fa": PackedFloat32Array([ 0.4, 0.0, 0.0, 0.0 ]),
		"fb": PackedFloat32Array([ 0.0, 0.0, 0.0, 0.0 ]),
		"col": Vector3(0.1, 0.1, 0.1),
		"ref": Vector3(1.0, 1.0, 1.0),
		"rough": 0.8,
		"f0": 0.2,
		"cr": 0.0,
		"mu": 1.2,
	}

func createShapeStructCylinder():
	return {
		"type": PackedInt32Array([ SHAPE_TYPE_CYLINDER, SHAPE_TYPE_NULL, SHAPE_TYPE_NULL, SHAPE_TYPE_NULL ]),
		"ope": PackedInt32Array([ SHAPE_OPERATION_ASSIGN, SHAPE_OPERATION_NONE, SHAPE_OPERATION_NONE, SHAPE_OPERATION_NONE ]),
		"va": createPackedFloat32Mat4([ 0.8, -0.7, 2.2, 0.0 ]),
		"vb": createPackedFloat32Mat4([ -0.2, 0.3, 3.0, 0.0 ]),
		"fa": PackedFloat32Array([ 0.1, 0.0, 0.0, 0.0 ]),
		"fb": PackedFloat32Array([ 0.0, 0.0, 0.0, 0.0 ]),
		"col": Vector3(0.1, 0.1, 0.1),
		"ref": Vector3(1.0, 1.0, 1.0),
		"rough": 0.8,
		"f0": 0.2,
		"cr": 0.0,
		"mu": 1.2,
	}

func createHuman(pos: Vector3):
	var body = createShapeStructCylinder()
	body["va"][0] = 0.0 + pos.x
	body["va"][1] = 0.65 + pos.y
	body["va"][2] = pos.z
	body["vb"][0] = 0.0 + pos.x
	body["vb"][1] = -0.1 + pos.y
	body["vb"][2] = pos.z
	body["fa"][0] = 0.15
	body["ref"] = Vector3(0.9, 0.1, 0.1)
	shapes.append(body)
	var larm = createShapeStructCylinder()
	larm["va"][0] = 0.1 + pos.x
	larm["va"][1] = 0.5 + pos.y
	larm["va"][2] = pos.z
	larm["vb"][0] = 1.0 + pos.x
	larm["vb"][1] = 0.6 + pos.y
	larm["vb"][2] = pos.z
	larm["fa"][0] = 0.08
	larm["ref"] = Vector3(0.98, 0.98, 0.7)
	shapes.append(larm)
	var rarm = createShapeStructCylinder()
	rarm["va"][0] = -0.1 + pos.x
	rarm["va"][1] = 0.5 + pos.y
	rarm["va"][2] = pos.z
	rarm["vb"][0] = -0.5 + pos.x
	rarm["vb"][1] = -0.2 + pos.y
	rarm["vb"][2] = pos.z
	rarm["fa"][0] = 0.08
	rarm["ref"] = Vector3(0.98, 0.98, 0.7)
	shapes.append(rarm)
	var lleg = createShapeStructCylinder()
	lleg["va"][0] = 0.05 + pos.x
	lleg["va"][1] = -0.1 + pos.y
	lleg["va"][2] = pos.z
	lleg["vb"][0] = 0.2 + pos.x
	lleg["vb"][1] = -0.9 + pos.y
	lleg["vb"][2] = pos.z
	lleg["ref"] = Vector3(0.25, 0.25, 0.98)
	shapes.append(lleg)
	var rleg = createShapeStructCylinder()
	rleg["va"][0] = -0.05 + pos.x
	rleg["va"][1] = -0.1 + pos.y
	rleg["va"][2] = pos.z
	rleg["vb"][0] = -0.3 + pos.x
	rleg["vb"][1] = -0.9 + pos.y
	rleg["vb"][2] = pos.z
	rleg["ref"] = Vector3(0.25, 0.25, 0.98)
	shapes.append(rleg)
	var head = createShapeStructSphere()
	head["va"][0] = 0.0 + pos.x
	head["va"][1] = 0.85 + pos.y
	head["va"][2] = pos.z
	head["fa"][0] = 0.3
	head["ref"] = Vector3(1.0, 0.98, 0.98)
	shapes.append(head)


# Called when the node enters the scene tree for the first time.
func _ready():
	#shapes.append(createShapeStructDeepWall())
	#shapes.append(createShapeStructBackLight())
	shapes.append(createShapeStructFloor())
	shapes.append(createShapeStructCeiling())
	shapes.append(createShapeStructLeftWall())
	shapes.append(createShapeStructRightWall())
	sphere = createShapeStructSphere()
	shapes.append(sphere)
	createHuman(Vector3(0.2, -0.6, 3.2))

	material = self.material
	material.set_shader_parameter("seed", 0.65535)
	material.set_shader_parameter("max_iter", MAX_ITER)
	material.set_shader_parameter("focus", FOCUS)
	material.set_shader_parameter("f_val", F_VAL)
	setShapes()

func setShapes():
	# Set Materials
	var type: PackedInt32Array = PackedInt32Array()
	var ope: PackedInt32Array = PackedInt32Array()
	var va: PackedFloat32Array = PackedFloat32Array()
	var vb: PackedFloat32Array = PackedFloat32Array()
	var fa: PackedFloat32Array = PackedFloat32Array()
	var fb: PackedFloat32Array = PackedFloat32Array()
	var col: PackedVector3Array = PackedVector3Array()
	var ref: PackedVector3Array = PackedVector3Array()
	var rough: PackedFloat32Array = PackedFloat32Array()
	var f0: PackedFloat32Array = PackedFloat32Array()
	var cr: PackedFloat32Array = PackedFloat32Array()
	for i in range(len(shapes)):
		type.append_array(shapes[i]["type"])
		ope.append_array(shapes[i]["ope"])
		va.append_array(shapes[i]["va"])
		vb.append_array(shapes[i]["vb"])
		fa.append_array(shapes[i]["fa"])
		fb.append_array(shapes[i]["fb"])
		col.append(shapes[i]["col"])
		ref.append(shapes[i]["ref"])
		rough.append(shapes[i]["rough"])
		f0.append(shapes[i]["f0"])
		cr.append(shapes[i]["cr"])
	material.set_shader_parameter("numberOfShapes", min(len(shapes), NUM_SHAPE_MAX))
	material.set_shader_parameter("shape_type", type)
	material.set_shader_parameter("shape_ope", ope)
	material.set_shader_parameter("shape_va", va)
	material.set_shader_parameter("shape_vb", vb)
	material.set_shader_parameter("shape_fa", fa)
	material.set_shader_parameter("shape_fb", fb)
	material.set_shader_parameter("shape_col", col)
	material.set_shader_parameter("shape_ref", ref)
	material.set_shader_parameter("shape_rough", rough)
	material.set_shader_parameter("shape_f0", f0)
	material.set_shader_parameter("shape_cr", cr)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	t += delta
	var f = 0.6
	var f2 = 0.7
	sphere["va"][0] = -0.8 + 0.3 * sin(f * t * PI)
	sphere["va"][1] = 0.4 + 0.1 * cos(f2 * t * PI)
	setShapes()
