process.nextTick ->
  atom.workspace.getPaneItems().forEach ->
    atom.workspace.destroyActivePaneItem()
