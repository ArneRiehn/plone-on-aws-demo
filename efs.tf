resource "aws_efs_file_system" "plone_blobstorage" {
  creation_token = "efs-plone-blobstorage"
}

resource "aws_efs_mount_target" "efs_private_a" {
  file_system_id  = aws_efs_file_system.plone_blobstorage.id
  subnet_id       = aws_subnet.private_a.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "efs_private_b" {
  file_system_id  = aws_efs_file_system.plone_blobstorage.id
  subnet_id       = aws_subnet.private_b.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "plone_blobstorage" {
  file_system_id = aws_efs_file_system.plone_blobstorage.id

  root_directory {
    path = "/blobstorage"
    creation_info {
      owner_gid   = 500
      owner_uid   = 500
      permissions = "755"
    }
  }
}
