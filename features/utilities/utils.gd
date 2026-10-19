class_name Utils
## Class with helper functions.


static func call_node(node: Node, method: StringName, ...args: Array) -> void:
	if node.has_method(method):
		if node.get_method_argument_count(method) == 0:
			node.call(method)
		else:
			node.call(method, args)


## Use only if there should be one method called. Avoid unnessesary [code]for[/code] looping.
static func call_nodes(nodes: Array[Node], method: StringName, ...args: Array) -> void:
	for node: Node in nodes:
		if node.has_method(method):
			if node.get_method_argument_count(method) == 0:
				node.call(method)
			else:
				node.call(method, args)
