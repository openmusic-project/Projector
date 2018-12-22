(in-package :om);=======================================;MENU;=======================================(defclass! presentador ()  ((folder :initform nil :initarg :folder :accessor folder)   (patch-list :accessor patch-list))  (:icon 128))(defmethod initialize-instance :after ((self presentador) &rest l )  (declare (ignore l))  (let ((folder (search-the-folder *current-workspace* (list! (folder self)))))    (when folder      (setf (patch-list self)             (loop for item in (elements folder)                  when (and (patch-p item) (not (maquette-p item)))                   collect (load-patch item)))      (setf (patch-list self)             (sort (patch-list self) 'string< :key 'name)))))(defun find-folder (cont name)  (let ((elems (elements cont))        rep)    (loop for item in elems          while (not rep) do          (when (folder-p item)            (setf rep (if (string-equal name (name item)) item))))    rep))(defun search-the-folder (container list)   (cond    ((null list) (om-beep-msg  "bad folder name"))    ((= (length list) 1)     (let ((folder (find-folder container (car list))))       (if folder folder (om-beep-msg " bad folder name"))))    (t      (let ((folder (find-folder container (car list))))       (if folder (search-the-folder folder (cdr list))           (om-beep-msg  " bad folder name"))))));=======================================;EDITOR;=======================================(in-package :om)(defmethod Class-has-editor-p ((self presentador)) (patch-list self))(defmethod get-boxsize ((self presentador)) (om-make-point 40 70))(defmethod get-editor-class ((self presentador)) 'preEditor)(defmethod draw-obj-in-rect ((self  presentador) x x1 y y1 edparams  view)   t);------------------------------------; EDITOR ;------------------------------------(defclass preeditor (object-editor patchEditor)   ((current :initform 0 :accessor current)   (mode :initform nil :accessor mode)))(defmethod object ((Self preeditor))   (nth (current self) (patch-list (slot-value self 'object))))(defmethod hwmanypatches ((Self preeditor))   (length (patch-list (slot-value self 'object))))(defmethod get-editor-panel-class ((self preeditor))  'prePanel)(defclass prePanel (patchpanel) ())(defmethod object ((Self prePanel))   (object (om-view-container self)))(defmethod set-editor-patch ((Self preeditor) num)  (let (object)    (setf (editorframe (object self)) nil)    (setf (current self) num)    (setf object (object self))    (setf (editorframe (object self)) self)    (om-set-window-title (om-view-window self) "Patch Presenter")    (loop for item in (om-subviews (panel self)) do (om-remove-subviews (panel self) item ))    (mapc #'(lambda (elem)              (let ((newframe (make-frame-from-callobj elem)))                (om-add-subviews  (panel self) newframe)                (add-subview-extra newframe))) (get-elements object))    (mapc #'(lambda (elem)              (update-graphic-connections elem (get-elements object))) (get-subframes (panel self)))  (change-text (title-bar self) (name object)))  (om-invalidate-view self))(defmethod initialize-instance :after ((Self preeditor) &rest L)    (declare (ignore l))   (set-editor-patch self 0));------------------------------------;ACTIONS;------------------------------------(defmethod init-titlebar ((self preeditor))  (call-next-method)  (apply 'om-add-subviews          (cons (title-bar self)                (loop for icon in '("first" "prev" "next" "last")                     for fun in '(start-patch back-patch fw-patch last-patch)                     for xx = 180 then (+ xx 21)                      collect                      (let ((f fun))                        (om-make-view 'om-icon-button :position (om-make-point xx 2) :size (om-make-point 22 22)                                     :icon1 icon :icon2 (string+ icon "-pushed")                                     :action #'(lambda (item) (funcall f (panel self)))))                 ))         ))(defmethod start-patch ((Self prePanel))  (set-editor-patch (editor self) 0))(defmethod back-patch ((Self prePanel))  (set-editor-patch (editor self) (max 0 (- (current (editor self)) 1))))(defmethod fw-patch ((Self prePanel))  (set-editor-patch (editor self) (min (- (hwmanypatches (editor self)) 1) (+ (current (editor self)) 1))))(defmethod last-patch ((Self prePanel))  (set-editor-patch (editor self) (- (hwmanypatches (editor self)) 1)))(defmethod handle-key-event ((self prePanel) key)  (case key    (:om-key-tab (fw-patch self))    (otherwise (call-next-method))))