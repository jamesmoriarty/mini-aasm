# frozen_string_literal: true

require "test_helper"

describe MiniAASM do
  before do
    @subject = PeriodicJob.new
  end

  describe "#states" do
    it "returns states" do
      _(@subject.states).must_equal %i[waiting executing terminated]
    end
  end

  describe "#current_state" do
    it "returns state" do
      _(@subject.current_state).must_equal :waiting
    end
  end

  describe "#set_current_state" do
    it "returns new state" do
      _(@subject.set_current_state(:terminated)).must_equal :terminated
    end

    it "raises exception with invalid state" do
      assert_raises(MiniAASM::UndefinedState) { @subject.set_current_state(:cooked) }
    end
  end

  describe ".aasm" do
    describe ".event" do
      describe ".transistions" do
        it "change" do
          _(@subject.work_succeeded!).must_equal :executing
        end

        it "multiple matching" do
          _(@subject.work_succeeded!).must_equal :executing
          _(@subject.work_failed!).must_equal :terminated
        end

        it "persist" do
          _(@subject.work_succeeded!).must_equal :executing
          _(@subject.work_succeeded!).must_equal :waiting
        end

        it "raises exception without matching" do
          _(@subject.set_current_state(:terminated)).must_equal :terminated
          assert_raises(MiniAASM::InvalidTransition) { @subject.work_succeeded! }
        end

        describe "guard" do
          it "raises exception when eval to false" do
            @subject = PeriodicJob.new(ready: false)

            assert_raises(MiniAASM::InvalidTransition) { @subject.work_succeeded! }
          end
        end
      end
    end
  end
end

binding.pry