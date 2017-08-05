function FIXBOOKREAD_ON_INIT(addon, frame)
  -- copy base from bookitemread.lua
  VIEW_BOOKITEM_PAGE = function(frame, page)
    local textObj		= GET_CHILD(frame, "text_left", "ui::CFlowText");
    local textObj2		= GET_CHILD(frame, "text_right", "ui::CFlowText");

    textObj:SetText(' ');
    textObj:ClearText();
    textObj2:SetText(' ');
    textObj2:ClearText();

    local dialogTable		= GetClass( 'DialogText', g_bookClassName);

    if dialogTable == nil then
      COLSE_BOOK_ITEM(frame);
      return;
    end

    local text = dialogTable.Text;
    local textL = '';
    local textR = '';
    for i = 1, page do
    
      textL = '';
      textR = '';
      -- left
      local index = BookTextFind(text, "{np}");
      if index == -1 then
        g_maxBookPage = page;
        textL = BookTextSubString(text, 0, string.len(text));
        break;
      end
      
      textL = BookTextSubString(text, 0, index +4);
      text = BookTextSubString(text, index + 4, string.len(text));

      -- check MAX_BOOK_TEXT_LEN
      if string.len(textL) > MAX_BOOK_TEXT_LEN then
        local tempStr = '';
        local beforeStr = '';
        local curStr = '';
        for j = 1, 100 do
          index = BookTextFind(textL, "{nl}");
          if string.len(curStr) > MAX_BOOK_TEXT_LEN then

            text = tempStr .. textL .. text;
            textL = beforeStr .. '{np}';
            break;
          elseif index == -1 then

            text = textL .. text;
            textL = curStr .. '{np}';
            break;
          end

          beforeStr = beforeStr .. tempStr;
          tempStr = BookTextSubString(textL, 0, index + 4);
          curStr = beforeStr .. tempStr;

          textL = BookTextSubString(textL, index + 4, string.len(textL));
        end
      end
      ----------------
      
      
      -- right
      index = BookTextFind(text, "{np}");
      if index == -1 then
        g_maxBookPage = page;
        textR = BookTextSubString(text, 0, string.len(text));
        break;
      end
      textR = BookTextSubString(text, 0, index +4);
      text = BookTextSubString(text, index + 4, string.len(text));

      -- check MAX_BOOK_TEXT_LEN
      if string.len(textR) > MAX_BOOK_TEXT_LEN then
        local tempStr = '';
        local beforeStr = '';
        local curStr = '';
        for j = 1, 100 do
          index = BookTextFind(textR, "{nl}");
          if string.len(curStr) > MAX_BOOK_TEXT_LEN then

            text = tempStr .. textR .. text;
            textR = beforeStr .. '{np}';
            break;
          elseif index == -1 then

            text = textR .. text;
            textR = curStr .. '{np}';
            break;
          end

          beforeStr = beforeStr .. tempStr;
          tempStr = BookTextSubString(textR, 0, index + 4);
          curStr = beforeStr .. tempStr;

          textR = BookTextSubString(textR, index + 4, string.len(textR));
        end
      end
      -----------
    end

    --TestNotePad(textR)

    -- fix code below.
    index = BookTextFind(textL, "{np}");
    textL = BookTextSubString(textL, 0, index);
    index = BookTextFind(textR, "{np}");
    textR = BookTextSubString(textR, 0, index);
    -- fix code above.

    textObj:SetText(textL);
      textObj:SetFontName('bookfont');
    textObj:SetFlowSpeed(200);

    textObj2:SetText(textR);
      textObj2:SetFontName('bookfont');
    textObj2:SetFlowSpeed(200);


    local prevBtn		= GET_CHILD(frame, "prevBtn", "ui::CButton");
    local nextBtn		= GET_CHILD(frame, "nextBtn", "ui::CButton");

    if g_bookPage == 1 then
      prevBtn:ShowWindow(0);
      nextBtn:ShowWindow(1);
    elseif g_maxBookPage > 0 and g_bookPage == g_maxBookPage then		
      prevBtn:ShowWindow(1);
      nextBtn:ShowWindow(0);
    else		
      prevBtn:ShowWindow(1);
      nextBtn:ShowWindow(1);
    end
  end
end