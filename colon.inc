%define last_node 0

%macro colon 2
	%ifid %2
		%2:
		dq last_node
	%define last_node %2
	%endif
	%ifstr %1
		dq %1, 0
	%endif
%endmacro
