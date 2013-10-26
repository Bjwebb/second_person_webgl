window.onload = ->
  if (location.hash != '#1' && location.hash != '#2')
    alert("Pick a player!");
  
  player_id = location.hash.slice(1)
  other_id = if (player_id == "1") then "2" else "1"
  
  peer = new Peer(player_id, {key: 'bt01ki4in04tpgb9'})
  other_conn = peer.connect(other_id);

  # set the scene size
  WIDTH = window.innerWidth
  HEIGHT = window.innerHeight

  # set some camera attributes
  VIEW_ANGLE = 45
  ASPECT = 1 #Temporary, reset below
  NEAR = 0.1
  FAR = 10000

  # get the DOM element to attach to
  # - assume we've got jQuery to hand
  $container = $("#container")

  # create a WebGL renderer, camera
  # and a scene
  renderer = new THREE.WebGLRenderer()
  cameras = [
    new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR),
    new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR),
    new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR),
    new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR)
    ]
  scene = new THREE.Scene()

  # the camera starts at 0,0,0 so pull it back
  if (player_id == "1")
    cameras[1].position.z = 300
  else
    cameras[0].position.z = 300
  cameras[2].position.x = 300
  cameras[3].position.y = 1000
  cameras[3].rotation.x = -Math.PI/2

  # start the renderer
  renderer.setSize WIDTH, HEIGHT

  # attach the render-supplied DOM element
  $container.append renderer.domElement

  # create the sphere's material
  colors = [0xCC0000, 0x00CC00, 0x0000CC, 0xCCCC00, 0xCC00CC, 0x00CCCC]

  cubeGeometry = new THREE.CubeGeometry(100, 100, 100)

  for camera,i in cameras
    material = new THREE.MeshLambertMaterial(color:colors[i%colors.length])
    cube = new THREE.Mesh(cubeGeometry, material)
    camera.add cube
    scene.add camera

  floor = new THREE.Mesh(new THREE.PlaneGeometry(1000, 1000), new THREE.MeshLambertMaterial(0xCCCCCC))
  floor.rotation.x = -Math.PI/2
  floor.position.y = -100
  scene.add floor


  # create a point light
  pointLight = new THREE.PointLight(0xFFFFFF)

  # set its position
  pointLight.position.x = 10
  pointLight.position.y = 50
  pointLight.position.z = 130

  # add to the scene
  scene.add pointLight

  animate = ->
    requestAnimationFrame animate
    render()


  render = ->
    views_x = Math.ceil(Math.sqrt(cameras.length))
    views_y = views_x
    view_width = WIDTH/views_x
    view_height = HEIGHT/views_y
    renderer.enableScissorTest(true)
    for camera,i in cameras
      x = i%views_x
      y = Math.floor(i/views_y)
      camera.aspect = view_width/view_height
      # FIXME don't do this every frame
      camera.updateProjectionMatrix()
      renderer.setViewport(x*view_width, y*view_height, view_width, view_height)
      renderer.setScissor(x*view_width, y*view_height, view_width, view_height)
      renderer.render scene, camera

  $(document).keydown (event) ->
    camera = cameras[0]
    switch event.which
      when 37 then camera.rotation.y += 0.1
      when 38
        camera.position.x -= 10*Math.sin(camera.rotation.y)
        camera.position.z -= 10*Math.cos(camera.rotation.y)
      when 39 then camera.rotation.y -= 0.1
      when 40
        camera.position.x += 10*Math.sin(camera.rotation.y)
        camera.position.z += 10*Math.cos(camera.rotation.y)

    other_conn.on('open', () ->
      conn.send(
        event: 'move',
        position: camera.position,
        rotation: camera.rotation
      )
    )

    peer.on('connection', (conn) ->
      conn.on('data', (data) ->
        switch data.event
          when 'move'
            camera2.position = data.position
            camera2.rotation = data.rotation
      )
    )

  # draw!
  animate()
 
