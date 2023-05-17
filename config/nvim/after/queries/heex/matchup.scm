(tag) @scope.tag

(start_tag (tag_name) @open.tag)
(end_tag
  (tag_name) @close.tag)

(self_closing_tag
  (tag_name) @open.selftag
  "/>" @close.selftag) @scope.selftag


(slot) @scope.slot

(start_slot (slot_name) @open.slot)
(end_slot
  (slot_name) @close.slot)

(self_closing_slot
  (slot_name) @open.selfslot
  "/>" @close.selfslot) @scope.selfslot


(component) @scope.component

(start_component (component_name) @open.component)
(end_component
  (component_name) @close.component)

(self_closing_component
  (component_name) @open.selfcomponent
  "/>" @close.selfcomponent) @scope.selfcomponent
