using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace SketchShareApi.Migrations
{
    /// <inheritdoc />
    public partial class migaration1 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Likes_Posts_PostId",
                table: "Likes");

            migrationBuilder.DropForeignKey(
                name: "FK_Likes_Users_UserId",
                table: "Likes");

            migrationBuilder.DropForeignKey(
                name: "FK_Posts_Images_ImageId",
                table: "Posts");

            migrationBuilder.DropForeignKey(
                name: "FK_Posts_Roles_PostRoleId",
                table: "Posts");

            migrationBuilder.DropForeignKey(
                name: "FK_Posts_Users_UserId",
                table: "Posts");

            migrationBuilder.DropForeignKey(
                name: "FK_Users_Roles_RoleId",
                table: "Users");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Users",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_Posts_ImageId",
                table: "Posts");

            migrationBuilder.DropColumn(
                name: "AvatarImage",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "AvatarUrl",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "ImageId",
                table: "Posts");

            migrationBuilder.RenameColumn(
                name: "RoleId",
                table: "Users",
                newName: "Role_Id");

            migrationBuilder.RenameColumn(
                name: "Id",
                table: "Users",
                newName: "Avatar");

            migrationBuilder.RenameIndex(
                name: "IX_Users_RoleId",
                table: "Users",
                newName: "IX_Users_Role_Id");

            migrationBuilder.RenameColumn(
                name: "UserId",
                table: "Posts",
                newName: "User_Id");

            migrationBuilder.RenameColumn(
                name: "PostRoleId",
                table: "Posts",
                newName: "Image_Id");

            migrationBuilder.RenameIndex(
                name: "IX_Posts_UserId",
                table: "Posts",
                newName: "IX_Posts_User_Id");

            migrationBuilder.RenameIndex(
                name: "IX_Posts_PostRoleId",
                table: "Posts",
                newName: "IX_Posts_Image_Id");

            migrationBuilder.RenameColumn(
                name: "UserId",
                table: "Likes",
                newName: "User_Id");

            migrationBuilder.RenameColumn(
                name: "PostId",
                table: "Likes",
                newName: "Post_Id");

            migrationBuilder.RenameIndex(
                name: "IX_Likes_UserId",
                table: "Likes",
                newName: "IX_Likes_User_Id");

            migrationBuilder.RenameIndex(
                name: "IX_Likes_PostId",
                table: "Likes",
                newName: "IX_Likes_Post_Id");

            migrationBuilder.AlterColumn<int>(
                name: "Avatar",
                table: "Users",
                type: "integer",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "integer")
                .OldAnnotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn);

            migrationBuilder.AddColumn<int>(
                name: "Id_User",
                table: "Users",
                type: "integer",
                nullable: false,
                defaultValue: 0)
                .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn);

            migrationBuilder.AddColumn<int>(
                name: "Count",
                table: "Likes",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddPrimaryKey(
                name: "PK_Users",
                table: "Users",
                column: "Id_User");

            migrationBuilder.AddForeignKey(
                name: "FK_Likes_Posts_Post_Id",
                table: "Likes",
                column: "Post_Id",
                principalTable: "Posts",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Likes_Users_User_Id",
                table: "Likes",
                column: "User_Id",
                principalTable: "Users",
                principalColumn: "Id_User",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Posts_Images_Image_Id",
                table: "Posts",
                column: "Image_Id",
                principalTable: "Images",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Posts_Users_User_Id",
                table: "Posts",
                column: "User_Id",
                principalTable: "Users",
                principalColumn: "Id_User",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Users_Roles_Role_Id",
                table: "Users",
                column: "Role_Id",
                principalTable: "Roles",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Likes_Posts_Post_Id",
                table: "Likes");

            migrationBuilder.DropForeignKey(
                name: "FK_Likes_Users_User_Id",
                table: "Likes");

            migrationBuilder.DropForeignKey(
                name: "FK_Posts_Images_Image_Id",
                table: "Posts");

            migrationBuilder.DropForeignKey(
                name: "FK_Posts_Users_User_Id",
                table: "Posts");

            migrationBuilder.DropForeignKey(
                name: "FK_Users_Roles_Role_Id",
                table: "Users");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Users",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "Id_User",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "Count",
                table: "Likes");

            migrationBuilder.RenameColumn(
                name: "Role_Id",
                table: "Users",
                newName: "RoleId");

            migrationBuilder.RenameColumn(
                name: "Avatar",
                table: "Users",
                newName: "Id");

            migrationBuilder.RenameIndex(
                name: "IX_Users_Role_Id",
                table: "Users",
                newName: "IX_Users_RoleId");

            migrationBuilder.RenameColumn(
                name: "User_Id",
                table: "Posts",
                newName: "UserId");

            migrationBuilder.RenameColumn(
                name: "Image_Id",
                table: "Posts",
                newName: "PostRoleId");

            migrationBuilder.RenameIndex(
                name: "IX_Posts_User_Id",
                table: "Posts",
                newName: "IX_Posts_UserId");

            migrationBuilder.RenameIndex(
                name: "IX_Posts_Image_Id",
                table: "Posts",
                newName: "IX_Posts_PostRoleId");

            migrationBuilder.RenameColumn(
                name: "User_Id",
                table: "Likes",
                newName: "UserId");

            migrationBuilder.RenameColumn(
                name: "Post_Id",
                table: "Likes",
                newName: "PostId");

            migrationBuilder.RenameIndex(
                name: "IX_Likes_User_Id",
                table: "Likes",
                newName: "IX_Likes_UserId");

            migrationBuilder.RenameIndex(
                name: "IX_Likes_Post_Id",
                table: "Likes",
                newName: "IX_Likes_PostId");

            migrationBuilder.AlterColumn<int>(
                name: "Id",
                table: "Users",
                type: "integer",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "integer")
                .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn);

            migrationBuilder.AddColumn<string>(
                name: "AvatarImage",
                table: "Users",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "AvatarUrl",
                table: "Users",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "ImageId",
                table: "Posts",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddPrimaryKey(
                name: "PK_Users",
                table: "Users",
                column: "Id");

            migrationBuilder.CreateIndex(
                name: "IX_Posts_ImageId",
                table: "Posts",
                column: "ImageId");

            migrationBuilder.AddForeignKey(
                name: "FK_Likes_Posts_PostId",
                table: "Likes",
                column: "PostId",
                principalTable: "Posts",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Likes_Users_UserId",
                table: "Likes",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Posts_Images_ImageId",
                table: "Posts",
                column: "ImageId",
                principalTable: "Images",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Posts_Roles_PostRoleId",
                table: "Posts",
                column: "PostRoleId",
                principalTable: "Roles",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Posts_Users_UserId",
                table: "Posts",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Users_Roles_RoleId",
                table: "Users",
                column: "RoleId",
                principalTable: "Roles",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
