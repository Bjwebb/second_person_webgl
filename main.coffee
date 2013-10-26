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
  # Major FIXME
  ASPECT = (WIDTH/2) / HEIGHT
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
    new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR)
    ]
  scene = new THREE.Scene()

  # the camera starts at 0,0,0 so pull it back
  if (player_id == "1")
    cameras[1].position.z = 300
  else
    cameras[0].position.z = 300

  # start the renderer
  renderer.setSize WIDTH, HEIGHT

  # attach the render-supplied DOM element
  $container.append renderer.domElement

  # create the sphere's material
  sphereMaterial = new THREE.MeshLambertMaterial(color: 0xCC0000)
  sphereMaterial2 = new THREE.MeshLambertMaterial(color: 0x00CC00)

  cubeGeometry = new THREE.CubeGeometry(100, 100, 100)

  # create a new mesh with sphere geometry -
  # we will cover the sphereMaterial next!
  cube = new THREE.Mesh(cubeGeometry, sphereMaterial)
  cube2 = new THREE.Mesh(cubeGeometry, sphereMaterial2)
  cameras[0].add cube
  cameras[1].add cube2
  for camera in cameras
  #  cube = new THREE.Mesh(cubeGeometry, sphereMaterial)
  #  camera.add cube
    scene.add camera

  floor = new THREE.Mesh(new THREE.PlaneGeometry(1000, 1000), sphereMaterial)
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
    renderer.enableScissorTest ( true );
    renderer.setViewport(0, 0, WIDTH/2, HEIGHT);
    renderer.setScissor(0, 0, WIDTH/2, HEIGHT);
    renderer.render scene, cameras[0]
    renderer.setViewport(WIDTH/2, 0, WIDTH/2, HEIGHT);
    renderer.setScissor(WIDTH/2, 0, WIDTH/2, HEIGHT);
    renderer.render scene, cameras[1]

  $(document).keydown (event) ->
    camera = cameras[0]
    views = Math.ceil(Math.sqrt(camera.length))
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
 
