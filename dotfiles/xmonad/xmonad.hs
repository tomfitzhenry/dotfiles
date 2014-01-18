import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Layout.MouseResizableTile
import XMonad.Prompt
import XMonad.Prompt.Window
import XMonad.Prompt.RunOrRaise
import XMonad.Util.Run(spawnPipe)
import XMonad.Util.EZConfig(additionalKeys)
import System.IO

import Data.Char (toLower)
import Data.List (isInfixOf)
import Data.List.Split (splitOn)

myModMask :: KeyMask
myModMask = mod4Mask

ws_web = "1:web"
ws_mail = "2:mail"
ws_music = "4:music"
ws_dl = "5:dl"
myWorkspaces = [ws_web,ws_mail,"3:term",ws_music,ws_dl] ++ map show [6..9]

-- `xprop | grep WM_CLASS` then click on window, to find an application's class/name
myManageHook = composeAll
    [ className =? "Firefox" --> doShift ws_web
    , className =? "Thunderbird" --> doShift ws_mail
    , className =? "Spotify" --> doShift ws_music
    , title =? "Transmission" --> doShift ws_dl
    ]

main = do
    xmproc <- spawnPipe "/usr/bin/xmobar /home/tom/.xmobarrc"

    xmonad $ defaultConfig
        { manageHook = manageDocks <+> myManageHook
        , terminal   = "emacsclient -c --eval '(eshell \"foo\")'"
        , layoutHook = avoidStruts $ (mouseResizableTile ||| layoutHook defaultConfig)
        , logHook = dynamicLogWithPP xmobarPP
                        { ppOutput = hPutStrLn xmproc
                        , ppTitle = xmobarColor "green" "" . shorten 50
                        }
        , modMask = myModMask
        , workspaces = myWorkspaces
        }
        `additionalKeys`
        [ ((myModMask .|. shiftMask, xK_g), windowPromptGoto myXPConfig)
        , ((myModMask .|. shiftMask, xK_b), windowPromptBring myXPConfig)
        , ((myModMask .|. shiftMask, xK_x), runOrRaisePrompt myXPConfig)
        ]

myXPConfig :: XPConfig
myXPConfig = greenXPConfig
    { autoComplete = Nothing
    , font = "-misc-fixed-*-*-*-*-20-*-*-*-*-*-*-*"
    , searchPredicate = orderIndepdentSubstringMatcher
    }


-- orderIndepdentSubstringMatcher "fire trel" "trello - Firefox" -> True
-- Terrible name. Shut up, naming is hard.
orderIndepdentSubstringMatcher :: String -> String -> Bool
orderIndepdentSubstringMatcher inputString windowTitle = all (\word -> word `matchesAtLeastOneWordOf` windowTitle) $ split inputString
    where
        word `matchesAtLeastOneWordOf` window = any (isInfixOf word) (split window)
        split :: String -> [String]
        split s = splitOn " " $ map toLower s
