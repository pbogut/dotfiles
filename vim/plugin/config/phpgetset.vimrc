" phpgetset config
let g:phpgetset_insertPosition = 2 " below current block
let b:phpgetset_insertPosition = 2 " below current block
let g:phpgetset_getterTemplate =
      \ "    \n" .
      \ "    /**\n" .
      \ "     * Get %varname%\n" .
      \ "     *\n" .
      \ "     * @return %varname%\n" .
      \ "     */\n" .
      \ "    public function %funcname%()\n" .
      \ "    {\n" .
      \ "        return $this->%varname%;\n" .
      \ "    }"

let g:phpgetset_setterTemplate =
      \ "    \n" .
      \ "    /**\n" .
      \ "     * Set %varname%.\n" .
      \ "     *\n" .
      \ "     * @param %varname% - value to set.\n" .
      \ "     * @return $this\n" .
      \ "     */\n" .
      \ "    public function %funcname%($%varname%)\n" .
      \ "    {\n" .
      \ "        $this->%varname% = $%varname%;\n" .
      \ "        return $this;\n" .
      \ "    }"
