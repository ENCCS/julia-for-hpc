! julia_fortran.f90

module julia_fortran
   implicit none
   public
   contains

   real(8) function add(a, b)
      implicit none
      real(8), intent(in)  :: a, b
      add = a + b
      return
   end function add

   subroutine addsub(x, y, a, b)
      implicit none
      real(8), intent(out) :: x, y
      real(8), intent(in)  :: a, b
      x = a + b
      y = a - b
      return
   end subroutine addsub

   subroutine concatenate(x, a, b)
      implicit none
      character(*), intent(out) :: x
      character(*), intent(in)  :: a, b
      x = a // b
      return
   end subroutine concatenate

   subroutine add_array(x, a, b, n)
      implicit none
      integer, intent(in)  :: n
      real(8), intent(out) :: x(n)
      real(8), intent(in)  :: a(n), b(n)
      x = a + b
      return
   end subroutine add_array

end module julia_fortran
