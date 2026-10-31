@tool
class_name Waterfall
extends Resource
## A waterfall in a region design: water running over the land from `top`
## down to `bottom`, where it falls into a pool. The land under it is shaped
## by the set's landforms (a cliff such as a plateau's edge, a valley for the
## pool); `Waters` draws the water over whatever ground is there.
## Positions are world metres, x east and y north, like Landform's.

## Where the water starts, on the high ground (x east, y north).
@export var top: Vector2 = Vector2.ZERO
## Where it lands, in the middle of its pool.
@export var bottom: Vector2 = Vector2.ZERO
## Metres across the falling water.
@export var width: float = 8.0
## Metres from the pool's middle to its shore.
@export var pool_radius: float = 8.0
## Metres the pool's surface lies above the ground at its middle.
@export var pool_depth: float = 2.0
## The pool's surface (absolute), for a fall into water poured elsewhere: then it
## replaces `pool_depth`, and with `pool_radius` 0 no pool of its own is drawn.
@export var pool_level: float = -INF
